#!/usr/bin/env python3
"""Render assets/demo.svg, the terminal animation used by the README.

The animation is declarative SVG (SMIL), so every renderer plays it
without a media player and without JavaScript. Run from the repository
root:

    python3 tools/make-demo.py
"""

from pathlib import Path
from xml.sax.saxutils import escape

WIDTH, HEIGHT = 720, 306
TITLE_BAR = 40
CYCLE = 12.0

BACKGROUND = "#0d1117"
TITLE_BACKGROUND = "#161b22"
TITLE_TEXT = "#8b949e"
PROMPT = "#3fb950"
COMMAND = "#c9d1d9"
LABEL = "#8b949e"
NUMBERS = "#58a6ff"
STARS = "#d2a8ff"
CURSOR = "#c9d1d9"

FONT = "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"
FONT_SIZE = 15
CHAR_WIDTH = 9.0
LEFT = 28
PROMPT_WIDTH = 18
TEXT_START = LEFT + PROMPT_WIDTH
VALUE_COLUMN = 112
FIRST_LINE = 72
LINE_HEIGHT = 28
CURSOR_INSET = 2

TYPING = 0.055
START_ONE = 0.35
START_TWO = 2.95
HOLD = 11.4

COMMAND_ONE = "./euromillions.sh"
OUTPUT_ONE = [("Numbers:", "4 8 13 36 46", NUMBERS), ("Stars:", "3 12", STARS)]
COMMAND_TWO = "./euromillions.sh --lang fr"
OUTPUT_TWO = [("Numéros:", "17 19 20 27 48", NUMBERS), ("Étoiles:", "5 12", STARS)]


def key(time):
    """Normalise a time in seconds to the animation cycle."""
    return round(time / CYCLE, 4)


def text(x, y, value, fill, extra=""):
    return (
        f'<text x="{x}" y="{y}" fill="{fill}"{extra}>'
        f"{escape(value)}</text>"
    )


def fade_in(at):
    """Opacity animation: hidden until at, visible afterwards."""
    return (
        f'<animate attributeName="opacity" values="0;1" keyTimes="0;{key(at)}" '
        f'dur="{CYCLE}s" calcMode="discrete" repeatCount="indefinite"/>'
    )


def typing(width, start, end):
    """Clip width animation for a typewriter effect."""
    return (
        f'<animate attributeName="width" values="0;0;{width};{width}" '
        f'keyTimes="0;{key(start)};{key(end)};1" dur="{CYCLE}s" '
        f'repeatCount="indefinite"/>'
    )


def cursor_move(width, start, end):
    """Cursor x position, following the typed text."""
    return (
        f'<animate attributeName="x" values="{TEXT_START};{TEXT_START};'
        f'{TEXT_START + width};{TEXT_START + width}" '
        f'keyTimes="0;{key(start)};{key(end)};1" dur="{CYCLE}s" '
        f'repeatCount="indefinite"/>'
    )


def build():
    width_one = len(COMMAND_ONE) * CHAR_WIDTH
    width_two = len(COMMAND_TWO) * CHAR_WIDTH
    end_one = START_ONE + len(COMMAND_ONE) * TYPING
    end_two = START_TWO + len(COMMAND_TWO) * TYPING

    out = []
    out.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" '
               f'viewBox="0 0 {WIDTH} {HEIGHT}" role="img" aria-labelledby="title desc">')
    out.append('<title id="title">Terminal session running euromillions.sh</title>')
    out.append('<desc id="desc">The script prints five numbers and two stars, then prints '
               'the same draw in French.</desc>')

    out.append("<defs>")
    out.append(
        f'<clipPath id="typing-one"><rect x="{TEXT_START}" y="{FIRST_LINE - 14}" '
        f'width="0" height="22">{typing(width_one, START_ONE, end_one)}</rect></clipPath>'
    )
    out.append(
        f'<clipPath id="typing-two"><rect x="{TEXT_START}" y="{FIRST_LINE + 4 * LINE_HEIGHT - 14}" '
        f'width="0" height="22">{typing(width_two, START_TWO, end_two)}</rect></clipPath>'
    )
    out.append("</defs>")

    out.append(f'<rect width="{WIDTH}" height="{HEIGHT}" rx="12" fill="{BACKGROUND}"/>')
    out.append(f'<rect width="{WIDTH}" height="{TITLE_BAR}" rx="12" fill="{TITLE_BACKGROUND}"/>')
    out.append(f'<rect y="{TITLE_BAR - 12}" width="{WIDTH}" height="12" fill="{TITLE_BACKGROUND}"/>')
    for index, color in enumerate(("#ff5f56", "#ffbd2e", "#27c93f")):
        out.append(f'<circle cx="{24 + index * 20}" cy="{TITLE_BAR // 2}" r="6" fill="{color}"/>')
    out.append(text(WIDTH / 2, 25, "euromillions", TITLE_TEXT, ' text-anchor="middle" font-size="12"'))

    out.append(f'<g font-family="{FONT}" font-size="{FONT_SIZE}">')

    # First prompt and command, typed through a clip
    out.append(text(LEFT, FIRST_LINE, "$", PROMPT))
    out.append(f'<g clip-path="url(#typing-one)">')
    out.append(text(TEXT_START, FIRST_LINE, COMMAND_ONE, COMMAND))
    out.append("</g>")

    # Cursor for the first command
    out.append(
        f'<rect x="{TEXT_START}" y="{FIRST_LINE - 13}" width="8" height="{FONT_SIZE + 4}" '
        f'fill="{CURSOR}" opacity="0">{cursor_move(width_one, START_ONE, end_one)}'
        f'<animate attributeName="opacity" values="1;1;0;0" keyTimes="0;{key(START_ONE)};'
        f'{key(end_one)};1" dur="{CYCLE}s" calcMode="discrete" repeatCount="indefinite"/></rect>'
    )

    # First output
    for index, (label, value, color) in enumerate(OUTPUT_ONE):
        at = end_one + 0.15 + index * 0.35
        y = FIRST_LINE + (index + 1) * LINE_HEIGHT
        out.append(f'<g opacity="0">{fade_in(at)}')
        out.append(text(LEFT, y, label, LABEL))
        out.append(text(VALUE_COLUMN, y, value, color))
        out.append("</g>")

    # Second prompt, command and output
    second_line = FIRST_LINE + 4 * LINE_HEIGHT
    out.append(f'<g opacity="0">{fade_in(START_TWO - 0.3)}')
    out.append(text(LEFT, second_line, "$", PROMPT))
    out.append("</g>")
    out.append(f'<g clip-path="url(#typing-two)">')
    out.append(text(TEXT_START, second_line, COMMAND_TWO, COMMAND))
    out.append("</g>")
    out.append(
        f'<rect x="{TEXT_START}" y="{second_line - 13}" width="8" height="{FONT_SIZE + 4}" '
        f'fill="{CURSOR}" opacity="0">'
        f'<animate attributeName="opacity" values="0;1" keyTimes="0;{key(START_TWO - 0.3)}" '
        f'dur="{CYCLE}s" calcMode="discrete" repeatCount="indefinite"/>'
        f"{cursor_move(width_two, START_TWO, end_two)}"
        f"</rect>"
    )

    for index, (label, value, color) in enumerate(OUTPUT_TWO):
        at = end_two + 0.15 + index * 0.35
        y = second_line + (index + 1) * LINE_HEIGHT
        out.append(f'<g opacity="0">{fade_in(at)}')
        out.append(text(LEFT, y, label, LABEL))
        out.append(text(VALUE_COLUMN, y, value, color))
        out.append("</g>")

    out.append("</g>")
    out.append("</svg>")
    return "\n".join(out) + "\n"


def main():
    target = Path(__file__).resolve().parent.parent / "assets" / "demo.svg"
    target.write_text(build(), encoding="utf-8")
    print(f"wrote {target}")


if __name__ == "__main__":
    main()
