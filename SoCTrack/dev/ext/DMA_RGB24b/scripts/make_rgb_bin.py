#!/usr/bin/env python3
"""
make_rgb_bin.py -- concatene les plans sample_in_{r,g,b}.txt en une image binaire
                   au format memoire attendu par l'IP DMA24bUnit_mm2s.

Le fichier produit est l'image memoire exacte que le port m_axi de l'IP va lire :
il se charge tel quel en DDR sous xsct avec "dow -data <fichier> <adresse>".

Le format n'est pas code en dur : il est relu dans src/generics_n_options.h
(RGB_MM_PACKED_g, IMAGE_W_o, IMAGE_H_o, IMAGE_STRIDE_o), de sorte que le .bin
reste toujours coherent avec ce que decode DMA24b_mm2s_get_pixel().

  RGB_MM_PACKED_g = 1 : RGB888 packe, 3 o/px, ordre raster R,G,B,R,G,B,...
                        (R a l'adresse la plus basse, cf. DMA24b_mm2s_utils.h)
  RGB_MM_PACKED_g = 0 : XRGB8888, 1 mot 32b 0x00RRGGBB par pixel, soit en
                        memoire little-endian les octets B,G,R,0x00

Usage :
    ./scripts/make_rgb_bin.py
    ./scripts/make_rgb_bin.py --addr 0x01000000
    ./scripts/make_rgb_bin.py --check-ppm samples/output/sample_out_rgb.ppm
"""

import argparse
import os
import re
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# generics relus dans le header ; valeur = nom de la macro
NEEDED = ("IMAGE_W_o", "IMAGE_H_o", "IMAGE_STRIDE_o", "COMP_SIZE_g",
          "RGB_MM_PACKED_g", "AXI_MM_SIZE_g", "PX_PER_GROUP_g",
          "BEATS_PER_GROUP_g")


def parse_generics(header_path):
    """Extrait les #define utiles de generics_n_options.h.

    Les valeurs sont soit un entier litteral, soit le nom d'une autre macro
    (cas de IMAGE_STRIDE_o defini comme IMAGE_W_o) : on resout les alias.
    """
    try:
        with open(header_path, "r") as f:
            text = f.read()
    except IOError as e:
        sys.exit("ERREUR : impossible de lire %s (%s)" % (header_path, e))

    # Balayage sequentiel en tenant compte des "#if <macro> / #else / #endif" :
    # PX_PER_GROUP_g et BEATS_PER_GROUP_g sont definis deux fois dans le header,
    # une fois par branche de "#if RGB_MM_PACKED_g". Il faut donc ne retenir que
    # la branche active, sans quoi on lirait toujours les valeurs du cas XRGB.
    pat = re.compile(r"^\s*#define\s+(\w+)\s+\(?\s*([^)/\s]+)\s*\)?\s*(?://.*)?$")
    raw = {}
    stack = []  # une entree par niveau de conditionnelle : branche active ?
    for line in text.splitlines():
        s = line.strip()
        if s.startswith("#if"):
            m = re.match(r"#if\s+(\w+)\s*$", s)
            if m and m.group(1) in raw:
                try:
                    active = int(raw[m.group(1)], 0) != 0
                except ValueError:
                    active = True
            else:
                active = True  # garde d'inclusion, condition non evaluable : on garde
            stack.append(active)
            continue
        if s.startswith("#else"):
            if stack:
                stack[-1] = not stack[-1]
            continue
        if s.startswith("#endif"):
            if stack:
                stack.pop()
            continue
        if not all(stack):
            continue
        m = pat.match(line)
        if m:
            raw[m.group(1)] = m.group(2).strip()

    def resolve(name, depth=0):
        if name not in raw:
            sys.exit("ERREUR : #define %s introuvable dans %s" % (name, header_path))
        v = raw[name]
        try:
            return int(v, 0)
        except ValueError:
            if depth > 8:
                sys.exit("ERREUR : alias circulaire sur #define %s" % name)
            return resolve(v, depth + 1)

    g = dict((n, resolve(n)) for n in NEEDED)

    # controles de coherence : memes contraintes que DMA24b_mm2s_utils.h:37-45
    if g["COMP_SIZE_g"] != 8:
        sys.exit("ERREUR : ce script ne gere que COMP_SIZE_g = 8 (lu : %d)"
                 % g["COMP_SIZE_g"])
    if g["IMAGE_W_o"] % g["PX_PER_GROUP_g"]:
        sys.exit("ERREUR : IMAGE_W_o (%d) n'est pas multiple de PX_PER_GROUP_g (%d)"
                 % (g["IMAGE_W_o"], g["PX_PER_GROUP_g"]))
    if g["IMAGE_STRIDE_o"] % g["PX_PER_GROUP_g"]:
        sys.exit("ERREUR : IMAGE_STRIDE_o (%d) n'est pas multiple de PX_PER_GROUP_g (%d)"
                 % (g["IMAGE_STRIDE_o"], g["PX_PER_GROUP_g"]))
    if g["IMAGE_STRIDE_o"] < g["IMAGE_W_o"]:
        sys.exit("ERREUR : IMAGE_STRIDE_o (%d) < IMAGE_W_o (%d)"
                 % (g["IMAGE_STRIDE_o"], g["IMAGE_W_o"]))
    return g


def read_plane(path, w, h):
    """Lit un plan couleur : h lignes de w valeurs decimales (cf. tb.cpp:20-37)."""
    try:
        with open(path, "r") as f:
            values = f.read().split()
    except IOError as e:
        sys.exit("ERREUR : impossible d'ouvrir %s (%s)" % (path, e))

    if len(values) != w * h:
        sys.exit("ERREUR : %s contient %d valeurs, attendu %d (%dx%d)"
                 % (path, len(values), w * h, w, h))
    try:
        plane = [int(v) for v in values]
    except ValueError:
        sys.exit("ERREUR : valeur non entiere dans %s" % path)
    if min(plane) < 0 or max(plane) > 255:
        sys.exit("ERREUR : %s contient une valeur hors de 0..255" % path)
    return plane


def pack(plane_r, plane_g, plane_b, g):
    """Construit l'image memoire ligne par ligne, padding de stride inclus."""
    w, h, stride = g["IMAGE_W_o"], g["IMAGE_H_o"], g["IMAGE_STRIDE_o"]
    bpp = 3 if g["RGB_MM_PACKED_g"] else 4
    pad = bytes((stride - w) * bpp)

    buf = bytearray()
    for j in range(h):
        base = j * w
        if g["RGB_MM_PACKED_g"]:
            # octet 0 = R, octet 1 = G, octet 2 = B (adresse croissante)
            line = bytearray(w * 3)
            line[0::3] = bytes(plane_r[base:base + w])
            line[1::3] = bytes(plane_g[base:base + w])
            line[2::3] = bytes(plane_b[base:base + w])
        else:
            # 1 mot 32 bits 0x00RRGGBB, little-endian -> B,G,R,0x00 en memoire
            line = bytearray()
            for i in range(w):
                line += struct.pack("<I", (plane_r[base + i] << 16) |
                                          (plane_g[base + i] << 8) |
                                           plane_b[base + i])
        buf += line + pad
    return bytes(buf)


def check_ppm(ppm_path, data, g):
    """Compare le .bin au corps d'un PPM P6 produit par le testbench.

    Le corps d'un P6 est du RGB888 packe raster : il est bit-a-bit identique
    a l'image memoire quand RGB_MM_PACKED_g = 1 et stride = largeur.
    """
    if not g["RGB_MM_PACKED_g"]:
        print("  controle PPM ignore : sans objet en XRGB8888")
        return True
    if g["IMAGE_STRIDE_o"] != g["IMAGE_W_o"]:
        print("  controle PPM ignore : stride != largeur")
        return True
    try:
        with open(ppm_path, "rb") as f:
            blob = f.read()
    except IOError as e:
        print("  controle PPM ignore : %s" % e)
        return True

    # en-tete P6 : magic, largeur, hauteur, maxval, chacun suivi d'un blanc
    fields, pos = [], 2
    while len(fields) < 3:
        while pos < len(blob) and blob[pos:pos + 1].isspace():
            pos += 1
        start = pos
        while pos < len(blob) and not blob[pos:pos + 1].isspace():
            pos += 1
        fields.append(blob[start:pos])
    body = blob[pos + 1:]

    if body == data:
        print("  controle PPM : OK, %d octets identiques a %s"
              % (len(data), os.path.relpath(ppm_path, ROOT)))
        return True
    print("  controle PPM : ECHEC (%d octets de corps PPM vs %d produits)"
          % (len(body), len(data)))
    for k in range(min(len(body), len(data))):
        if body[k] != data[k]:
            print("    premiere difference a l'offset %d : PPM %02x / bin %02x"
                  % (k, body[k], data[k]))
            break
    return False


def main():
    p = argparse.ArgumentParser(
        description="Concatene sample_in_{r,g,b}.txt en une image .bin chargeable en DDR.")
    p.add_argument("--in-dir", default=os.path.join(ROOT, "samples", "input"),
                   help="repertoire des plans d'entree (defaut : samples/input)")
    p.add_argument("--prefix", default="sample_in",
                   help="prefixe des plans, lus <prefix>_r/_g/_b.txt (defaut : sample_in)")
    p.add_argument("-o", "--out", default=None,
                   help="fichier binaire produit (defaut : <in-dir>/<prefix>_rgb.bin)")
    p.add_argument("--header", default=os.path.join(ROOT, "src", "generics_n_options.h"),
                   help="header des generics (defaut : src/generics_n_options.h)")
    p.add_argument("--addr", default="0x10000000",
                   help="adresse DDR utilisee pour l'aide-memoire xsct (defaut : 0x10000000)")
    p.add_argument("--check-ppm", default=None, metavar="PPM",
                   help="verifie le .bin contre le corps d'un PPM P6 du testbench")
    args = p.parse_args()

    out = args.out or os.path.join(args.in_dir, args.prefix + "_rgb.bin")
    try:
        addr = int(args.addr, 0)
    except ValueError:
        sys.exit("ERREUR : adresse invalide : %s" % args.addr)

    g = parse_generics(args.header)
    w, h, stride = g["IMAGE_W_o"], g["IMAGE_H_o"], g["IMAGE_STRIDE_o"]
    bpp = 3 if g["RGB_MM_PACKED_g"] else 4
    fmt = "RGB888 packe (R,G,B)" if g["RGB_MM_PACKED_g"] else "XRGB8888 (0x00RRGGBB)"

    planes = []
    for c in "rgb":
        path = os.path.join(args.in_dir, "%s_%s.txt" % (args.prefix, c))
        planes.append(read_plane(path, w, h))

    data = pack(planes[0], planes[1], planes[2], g)

    try:
        with open(out, "wb") as f:
            f.write(data)
    except IOError as e:
        sys.exit("ERREUR : ecriture de %s impossible (%s)" % (out, e))

    # mots AXI par ligne et taille du buffer, memes formules que
    # MM_LINE_STRIDE_c / DDR_SIZE dans DMA24b_mm2s_utils.h:32-34
    beats_line = (stride // g["PX_PER_GROUP_g"]) * g["BEATS_PER_GROUP_g"]
    ddr_words = beats_line * h

    print("Format memoire : %s, %d octet(s)/pixel" % (fmt, bpp))
    print("Image          : %dx%d, stride %d pixels" % (w, h, stride))
    print("Bus m_axi      : %d bits, %d mot(s)/ligne, DDR_SIZE = %d mots"
          % (g["AXI_MM_SIZE_g"], beats_line, ddr_words))
    print("Fichier        : %s" % out)
    print("Taille         : %d octets (%d attendus)"
          % (len(data), ddr_words * g["AXI_MM_SIZE_g"] // 8))
    print("Premiers octets: %s ..." % " ".join("%02x" % b for b in data[:9]))

    ok = True
    if args.check_ppm:
        ok = check_ppm(args.check_ppm, data, g)

    first_word = struct.unpack("<I", data[:4])[0]
    print("")
    print("Chargement en DDR sous xsct (adresse parametrable via --addr) :")
    print("    connect")
    print('    targets -set -filter {name =~ "*Cortex-A9*#0"}')
    print("    # le controleur DDR doit etre initialise avant tout dow -data :")
    print("    # source <workspace>/.../ps7_init.tcl ; ps7_init")
    rel = os.path.relpath(out, os.getcwd())
    print("    dow -data %s 0x%08X" % (out if rel.startswith("..") else rel, addr))
    print("    mrd 0x%08X 4        ;# controle : le 1er mot doit valoir 0x%08X"
          % (addr, first_word))

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
