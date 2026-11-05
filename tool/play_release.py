#!/usr/bin/env python3
"""Upload an Android App Bundle to Google Play and create a release.

Uses the Google Play Developer API (androidpublisher v3) with a
service-account key that has Release Manager access to the app in
Play Console (Users and permissions). Keep that key out of git.

Defaults are deliberately safe: the Internal testing track, as a draft
release, so nothing reaches users until it is rolled out in Play Console.

    python3 tool/play_release.py --key ~/path/service-account.json \
        --aab build/app/outputs/bundle/release/app-release.aab \
        --notes docs/store/release_notes.txt

Requires: google-auth, requests.
"""
import argparse
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

API = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
UPLOAD = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications"
SCOPE = "https://www.googleapis.com/auth/androidpublisher"


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--key", required=True, help="service-account JSON key file")
    p.add_argument("--aab", required=True, help="signed .aab to upload")
    p.add_argument("--package", default="com.devsinntechnologies.abc.kids.learning")
    p.add_argument("--track", default="internal", choices=["internal", "alpha", "beta", "production"])
    p.add_argument("--status", default="draft", choices=["draft", "completed"],
                   help="draft: review and roll out in Play Console; completed: roll out now")
    p.add_argument("--notes", help="plain-text release notes (max 500 characters)")
    p.add_argument("--language", default="en-US", help="language code for the release notes")
    p.add_argument("--name", default=None, help="release name shown in Play Console (default: version)")
    a = p.parse_args()

    if a.track == "production" and a.status == "completed":
        print("Refusing to roll out to production in one step; create a draft and roll out in Play Console.")
        return 2

    creds = service_account.Credentials.from_service_account_file(a.key, scopes=[SCOPE])
    creds.refresh(Request())
    s = requests.Session()
    s.headers["Authorization"] = f"Bearer {creds.token}"

    def check(r: requests.Response, what: str) -> dict:
        if not r.ok:
            print(f"{what} failed ({r.status_code}): {r.text}")
            sys.exit(1)
        return r.json() if r.content else {}

    base = f"{API}/{a.package}"
    edit = check(s.post(f"{base}/edits"), "Open edit")["id"]
    print(f"Opened edit {edit}")
    try:
        with open(a.aab, "rb") as f:
            bundle = check(
                s.post(f"{UPLOAD}/{a.package}/edits/{edit}/bundles",
                       params={"uploadType": "media"},
                       headers={"Content-Type": "application/octet-stream"},
                       data=f, timeout=900),
                "Upload bundle")
        code = bundle["versionCode"]
        print(f"Uploaded bundle: versionCode {code}, sha256 {bundle.get('sha256', '?')}")

        release = {"versionCodes": [str(code)], "status": a.status, "name": a.name or str(code)}
        if a.notes:
            text = open(a.notes, encoding="utf-8").read().strip()
            if len(text) > 500:
                print(f"Release notes are {len(text)} characters; Play allows 500.")
                sys.exit(1)
            release["releaseNotes"] = [{"language": a.language, "text": text}]
        check(s.put(f"{base}/edits/{edit}/tracks/{a.track}", json={"track": a.track, "releases": [release]}),
              "Update track")
        print(f"Release set on track '{a.track}' as {a.status}")

        check(s.post(f"{base}/edits/{edit}:commit"), "Commit edit")
        print("Committed. Open Play Console → Test and release to review it.")
        return 0
    except SystemExit:
        s.delete(f"{base}/edits/{edit}")
        raise


if __name__ == "__main__":
    sys.exit(main())
