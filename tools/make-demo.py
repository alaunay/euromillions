#!/usr/bin/env python3
"""Render assets/demo.gif, the terminal animation used by the README.

The frames are drawn with Pillow so the result is reproducible and needs
no terminal recorder. Run from the repository root:

    python3 tools/make-demo.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WIDTH, HEIGHT = 720, 306
TITLE_BAR = 40
BACKGROUND = (13, 17, 23)
TITLE_BACKGROUND = (22, 27, 34)
TITLE_TEXT = (139, 148, 158)
PROMPT = (63, 185, 80)
COMMAND = (201, 209, 217)
LABEL = (139, 148, 158)
NUMBERS = (88, 166, 255)
STARS = (210, 168, 255)
CURSOR = (201, 209, 217)

FONT_CANDIDATES = (
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    "/usr/share/fonts/TTF/DejaVuSansMono.ttf",
    "/usr/share/fonts/truetype/noto/NotoMono-Regular.ttf",
)

FONT_SIZE = 15
LINE_HEIGHT = 28
LEFT = 28
VALUE_COLUMN = 112
FIRST_LINE = 72

TYPING_DELAY = 55
PAUSE = 400
LINE_PAUSE = 350
HOLD = 2600


def load_font():
    for path in FONT_CANDIDATES:
        if Path(path).exists():
            return ImageFont.truetype(path, FONT_SIZE)
    return ImageFont.load_default()


FONT = load_font()

COMMAND_ONE = "./euromillions.sh"
OUTPUT_ONE = [("Numbers:", "4 8 13 36 46", NUMBERS), ("Stars:", "3 12", STARS)]
COMMAND_TWO = "./euromillions.sh --lang fr"
OUTPUT_TWO = [("Numéros:", "17 19 20 27 48", NUMBERS), ("Étoiles:", "5 12", STARS)]


def window():
    image = Image.new("RGB", (WIDTH, HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(image)

    draw.rectangle((0, 0, WIDTH, TITLE_BAR), fill=TITLE_BACKGROUND)
    for index, color in enumerate(((255, 95, 86), (255, 189, 46), (39, 201, 63))):
        cx = 24 + index * 20
        draw.ellipse((cx - 6, TITLE_BAR // 2 - 6, cx + 6, TITLE_BAR // 2 + 6), fill=color)

    title = "euromillions"
    width = draw.textlength(title, font=FONT)
    draw.text(((WIDTH - width) / 2, 11), title, font=FONT, fill=TITLE_TEXT)
    return image


def prompt_line(draw, y, command, cursor):
    draw.text((LEFT, y), "$", font=FONT, fill=PROMPT)
    start = LEFT + draw.textlength("$ ", font=FONT)
    draw.text((start, y), command, font=FONT, fill=COMMAND)
    if cursor:
        x = start + draw.textlength(command, font=FONT) + 2
        draw.rectangle((x, y - 2, x + 8, y + FONT_SIZE + 2), fill=CURSOR)


def output_line(draw, y, label, value, color):
    draw.text((LEFT, y), label, font=FONT, fill=LABEL)
    draw.text((VALUE_COLUMN, y), value, font=FONT, fill=color)


def frame(command_one="", cursor_one=False, show_one=0, command_two="", cursor_two=False, show_two=0, show_prompt_two=False):
    image = window()
    draw = ImageDraw.Draw(image)

    prompt_line(draw, FIRST_LINE, command_one, cursor_one)
    for index, (label, value, color) in enumerate(OUTPUT_ONE[:show_one]):
        output_line(draw, FIRST_LINE + (index + 1) * LINE_HEIGHT, label, value, color)

    if show_prompt_two:
        prompt_line(draw, FIRST_LINE + 4 * LINE_HEIGHT, command_two, cursor_two)
    for index, (label, value, color) in enumerate(OUTPUT_TWO[:show_two]):
        output_line(draw, FIRST_LINE + (5 + index) * LINE_HEIGHT, label, value, color)

    return image


def build():
    """Return frames as (image, delay in ms) pairs."""
    frames = []

    def add(delay, **kwargs):
        frames.append((frame(**kwargs), delay))

    add(PAUSE)
    for end in range(1, len(COMMAND_ONE) + 1):
        add(TYPING_DELAY, command_one=COMMAND_ONE[:end], cursor_one=True)
    add(PAUSE, command_one=COMMAND_ONE)
    add(LINE_PAUSE, command_one=COMMAND_ONE, show_one=1)
    add(LINE_PAUSE * 3, command_one=COMMAND_ONE, show_one=2)

    add(200, command_one=COMMAND_ONE, show_one=2, cursor_two=True, show_prompt_two=True)
    for end in range(1, len(COMMAND_TWO) + 1):
        add(TYPING_DELAY, command_one=COMMAND_ONE, show_one=2, command_two=COMMAND_TWO[:end], cursor_two=True, show_prompt_two=True)
    add(PAUSE, command_one=COMMAND_ONE, show_one=2, command_two=COMMAND_TWO, show_prompt_two=True)
    add(LINE_PAUSE, command_one=COMMAND_ONE, show_one=2, command_two=COMMAND_TWO, show_two=1, show_prompt_two=True)
    add(LINE_PAUSE * 3, command_one=COMMAND_ONE, show_one=2, command_two=COMMAND_TWO, show_two=2, show_prompt_two=True)

    for _ in range(3):
        add(HOLD // 3 + 1, command_one=COMMAND_ONE, show_one=2, command_two=COMMAND_TWO, show_two=2, cursor_two=True, show_prompt_two=True)
        add(HOLD // 3 + 1, command_one=COMMAND_ONE, show_one=2, command_two=COMMAND_TWO, show_two=2, cursor_two=False, show_prompt_two=True)

    return frames


def save(frames, path):
    # A small adaptive palette (16 colours) smears the antialiased text
    # into greys, so keep enough entries for the accent colours
    palette = frames[-1][0].quantize(colors=128)
    images = [image.quantize(palette=palette, dither=Image.Dither.NONE) for image, _ in frames]
    durations = [delay for _, delay in frames]
    images[0].save(
        path,
        save_all=True,
        append_images=images[1:],
        duration=durations,
        loop=0,
        optimize=True,
    )


def main():
    target = Path(__file__).resolve().parent.parent / "assets" / "demo.gif"
    save(build(), target)
    print(f"wrote {target}")


if __name__ == "__main__":
    main()
