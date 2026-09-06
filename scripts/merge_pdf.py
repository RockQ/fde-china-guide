#!/usr/bin/env python3
"""Merge cover PNG + body PDF into final book PDF."""
import os
import sys

from PIL import Image
from pypdf import PdfReader, PdfWriter

COVER_PNG = "assets/ebook-cover.png"
BODY_PDF = "dist/_body_tmp.pdf"
COVER_PDF = "dist/_cover_tmp.pdf"


def main():
    book_name = sys.argv[1] if len(sys.argv) > 1 else "book.pdf"
    out_pdf = os.path.join("dist", book_name)

    os.makedirs("dist", exist_ok=True)

    # Convert cover PNG to PDF
    img = Image.open(COVER_PNG).convert("RGB")
    img.save(COVER_PDF, "PDF", resolution=150)

    # Merge: cover first, then body
    writer = PdfWriter()
    for page in PdfReader(COVER_PDF).pages:
        writer.add_page(page)
    for page in PdfReader(BODY_PDF).pages:
        writer.add_page(page)

    with open(out_pdf, "wb") as f:
        writer.write(f)

    # Cleanup temp files
    os.remove(COVER_PDF)
    os.remove(BODY_PDF)

    print(f"PDF merged: {out_pdf}")


if __name__ == "__main__":
    main()
