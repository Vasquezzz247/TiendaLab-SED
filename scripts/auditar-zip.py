"""Audita un ZIP de TiendaLab antes de entregarlo o al recibirlo. Solo biblioteca estándar.

Detecta archivos que nunca deben viajar (.env, sesiones PHP, temporales, herramientas descargadas,
imágenes tar, claves, .git) y secretos: los valores locales de DB_PASSWORD/DB_ROOT_PASSWORD del .env de
este equipo y patrones de tokens/llaves privadas. Nunca imprime valores secretos, solo el nombre de la entrada.
Código de salida: 0 limpio, 1 hay hallazgos, 2 uso incorrecto.
"""
from pathlib import Path, PurePosixPath
import argparse
import fnmatch
import json
import re
import sys
import zipfile

root = Path(__file__).resolve().parent.parent
PROHIBITED_SEGMENTS = {'.git', 'tmp', 'storage', 'tools', 'node_modules', 'vendor', 'backups', 'data', 'dist'}
PROHIBITED_NAMES = ['sess_*', '*.tar', '*.tar.gz', '*.tgz', '*.pem', '*.key', '*.log', 'php.zip', '.DS_Store', 'Thumbs.db']
TOKEN_PATTERN = re.compile(rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)')
MAX_SCAN = 64 * 1024 * 1024  # entradas más grandes se marcan por nombre y no se leen


def classify(name):
    parts = PurePosixPath(name).parts
    base = parts[-1] if parts else ''
    reasons = []
    if base == '.env' or (base.startswith('.env.') and base != '.env.example'):
        reasons.append('archivo de entorno')
    hit = PROHIBITED_SEGMENTS.intersection(parts[:-1] if len(parts) > 1 else ())
    if hit:
        reasons.append('carpeta excluida: ' + ', '.join(sorted(hit)))
    if any(fnmatch.fnmatch(base, pattern) for pattern in PROHIBITED_NAMES):
        reasons.append('tipo de archivo excluido')
    return reasons


def local_secrets():
    env = root / '.env'
    values = []
    if env.exists():
        for line in env.read_text(encoding='utf-8', errors='replace').splitlines():
            if line.startswith(('DB_PASSWORD=', 'DB_ROOT_PASSWORD=')):
                value = line.split('=', 1)[1].strip()
                if len(value) >= 12:
                    values.append(value.encode())
    return values


def audit(path):
    findings = []
    secrets = local_secrets()
    with zipfile.ZipFile(path) as archive:
        entries = [info for info in archive.infolist() if not info.is_dir()]
        names = [info.filename for info in entries]
        duplicates = sorted({n for n in names if names.count(n) > 1})
        for name in duplicates:
            findings.append({'entrada': name, 'motivo': 'entrada duplicada'})
        for info in entries:
            for reason in classify(info.filename):
                findings.append({'entrada': info.filename, 'motivo': reason})
            if info.file_size > MAX_SCAN:
                findings.append({'entrada': info.filename, 'motivo': 'demasiado grande para revisar su contenido'})
                continue
            data = archive.read(info)
            if any(secret in data for secret in secrets):
                findings.append({'entrada': info.filename, 'motivo': 'contiene un secreto local del .env'})
            if TOKEN_PATTERN.search(data):
                findings.append({'entrada': info.filename, 'motivo': 'patrón de token o llave privada'})
    return len(entries), len(secrets), findings


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('zip', type=Path, help='ZIP a auditar')
    parser.add_argument('--output', type=Path, help='Guardar el informe JSON (UTF-8)')
    args = parser.parse_args()
    if not args.zip.is_file() or not zipfile.is_zipfile(args.zip):
        print('No es un ZIP válido: %s' % args.zip, file=sys.stderr)
        return 2
    total, compared, findings = audit(args.zip)
    report = {'zip': args.zip.name, 'entradas': total, 'secretos_locales_comparados': compared,
              'hallazgos': len(findings), 'limpio': not findings, 'detalle': findings}
    text = json.dumps(report, ensure_ascii=False, indent=2) + '\n'
    if args.output:
        args.output.write_text(text, encoding='utf-8')
    sys.stdout.reconfigure(encoding='utf-8')
    if findings:
        shown = findings[:25]
        print('ZIP NO LIMPIO: %d hallazgos en %d entradas (%d secretos locales comparados)' % (len(findings), total, compared))
        for item in shown:
            print(' - %s: %s' % (item['entrada'], item['motivo']))
        if len(findings) > len(shown):
            print(' ... y %d más (ver --output)' % (len(findings) - len(shown)))
        return 1
    print('ZIP LIMPIO: %d entradas revisadas, %d secretos locales comparados, sin hallazgos.' % (total, compared))
    return 0


if __name__ == '__main__':
    sys.exit(main())
