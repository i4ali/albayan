#!/usr/bin/env python3
"""
Single-shot ASO screenshot generator via OpenRouter (Nano Banana Pro / Gemini 3 Pro image preview).

Sends a source simulator screenshot + a style-reference ASO image + a prompt,
saves the returned image. Cropping/resizing to App Store dimensions is done
afterward by the caller (sips).
"""

import argparse
import base64
import json
import os
import sys
import urllib.request
from pathlib import Path


def b64_data_url(path: Path) -> str:
    mime = "image/png" if path.suffix.lower() == ".png" else "image/jpeg"
    data = base64.b64encode(path.read_bytes()).decode()
    return f"data:{mime};base64,{data}"


def load_env_key(env_path: Path, key: str) -> str:
    if key in os.environ and os.environ[key]:
        return os.environ[key]
    if not env_path.exists():
        raise SystemExit(f"{key} not in env and {env_path} not found")
    for line in env_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        if k.strip() == key:
            return v.strip().strip('"').strip("'")
    raise SystemExit(f"{key} not found in {env_path}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", required=True, help="Path to source simulator screenshot")
    ap.add_argument("--reference", required=True, help="Path to style-reference ASO screenshot")
    ap.add_argument("--prompt", required=True, help="Prompt text")
    ap.add_argument("--output", required=True, help="Path to save returned image")
    ap.add_argument("--model", default="google/gemini-3-pro-image-preview")
    ap.add_argument("--env", default=str(Path(__file__).resolve().parent.parent / ".env"))
    args = ap.parse_args()

    api_key = load_env_key(Path(args.env), "OPENROUTER_API_KEY")

    payload = {
        "model": args.model,
        "modalities": ["image", "text"],
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": args.prompt},
                    {"type": "image_url", "image_url": {"url": b64_data_url(Path(args.source))}},
                    {"type": "image_url", "image_url": {"url": b64_data_url(Path(args.reference))}},
                ],
            }
        ],
    }

    req = urllib.request.Request(
        "https://openrouter.ai/api/v1/chat/completions",
        data=json.dumps(payload).encode(),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://albayan.app",
            "X-Title": "AlBayan ASO",
        },
        method="POST",
    )

    print(f"Calling {args.model} ...", file=sys.stderr)
    with urllib.request.urlopen(req, timeout=600) as resp:
        body = json.loads(resp.read().decode())

    msg = body["choices"][0]["message"]
    images = msg.get("images") or []
    if not images:
        # Surface helpful debug info
        print(json.dumps(body, indent=2)[:4000], file=sys.stderr)
        raise SystemExit("No image returned in response")

    url = images[0]["image_url"]["url"]
    if url.startswith("data:"):
        b64 = url.split(",", 1)[1]
        Path(args.output).write_bytes(base64.b64decode(b64))
    else:
        with urllib.request.urlopen(url, timeout=300) as r:
            Path(args.output).write_bytes(r.read())

    print(f"Saved: {args.output}", file=sys.stderr)


if __name__ == "__main__":
    main()
