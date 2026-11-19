"""Auditoría de archivos y ZIP Git. Solo biblioteca estándar; no cambia el índice."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import zipfile

def git(*args):
    return subprocess.check_output(['git', *args])

root = Path(__file__).resolve().parent.parent
os.chdir(root)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, help='Guardar evidencia JSON UTF-8 sin conversion de consola')
parser.add_argument('--github-zip', type=Path, help='ZIP de GitHub del mismo commit HEAD')
args = parser.parse_args()
before = git('status', '--porcelain', '-z')
head = git('rev-parse', 'HEAD').decode().strip()
names = git('ls-tree', '-r', '--name-only', '-z', 'HEAD').decode().split('\0')
def forbidden(name):
    return (name == '.env' or (name.startswith('.env.') and name != '.env.example')
            or name.startswith(('tools/php/', 'tmp/', 'node_modules/', 'vendor/', 'backups/', 'data/'))
            or name == 'tools/php.zip' or name.endswith(('.tar', '.tar.gz', '.pem', '.key', '.log')))

assert not any(forbidden(n) for n in names), 'Archivo excluido versionado'
objects = git('rev-list', '--objects', '--all').decode().splitlines()
assert not any(forbidden(line.split(' ',1)[1]) for line in objects if ' ' in line), 'Archivo excluido en historial'
secrets = []
if (root / '.env').exists():
    for line in (root / '.env').read_text().splitlines():
        if line.startswith(('DB_PASSWORD=', 'DB_ROOT_PASSWORD=')):
            value = line.split('=',1)[1]
            assert value, 'Secreto local vacio'
            secrets.append(value.encode())
blob_count = 0
for line in objects:
    oid = line.split(' ',1)[0]
    if git('cat-file', '-t', oid).strip() != b'blob':
        continue
    data = git('cat-file', 'blob', oid)
    assert not any(secret in data for secret in secrets), 'Secreto local encontrado: detener publicación'
    assert not re.search(rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)', data), 'Patron de secreto detectado'
    blob_count += 1

out = root / 'tmp' / 'tiendalab-auditoria.zip'
out.parent.mkdir(exist_ok=True)
subprocess.run(['git','archive','--format=zip','--output',str(out),'HEAD'], check=True)
pdfs = ['DefinicióndelProyecto(1).pdf', 'Propuesta_TiendaLab.pdf']
evidence = {'commit':head, 'zip':out.name, 'historial_blobs_revisados':blob_count,
            'secretos_locales_comparados':len(secrets), 'archivos_excluidos_en_git':0, 'pdfs':[]}
with zipfile.ZipFile(out) as archive:
    entries = archive.namelist()
    assert len(entries) == len(set(entries)), 'Entradas duplicadas'
    assert not any(forbidden(n) for n in entries)
    assert sorted(n for n in entries if n.lower().endswith('.pdf')) == sorted(pdfs), 'Nombres PDF inesperados'
    for name in pdfs:
        data = archive.read(name)
        assert data == (root/name).read_bytes() == git('show',f'HEAD:{name}'), 'PDF alterado'
        evidence['pdfs'].append({'nombre':name,'sha256':hashlib.sha256(data).hexdigest(),
                                 'utf8_flag':bool(archive.getinfo(name).flag_bits & 0x800),
                                 'copias':entries.count(name),'contenido_igual':True})
if args.github_zip:
    with zipfile.ZipFile(args.github_zip) as archive:
        entries = archive.namelist()
        assert len(entries) == len(set(entries)), 'Duplicados en ZIP GitHub'
        prefixes = {name.split('/')[0] for name in entries}
        assert len(prefixes) == 1, 'Raiz inesperada en ZIP GitHub'
        prefix = prefixes.pop() + '/'
        assert prefix.endswith('-' + head + '/'), 'ZIP GitHub no corresponde a HEAD; descargar el commit correcto'
        relative = [name[len(prefix):] for name in entries]
        assert not any(forbidden(name) for name in relative)
        assert sorted(name for name in relative if name.lower().endswith('.pdf')) == sorted(pdfs)
        for name in pdfs:
            assert archive.read(prefix + name) == git('show', f'HEAD:{name}'), 'PDF GitHub alterado'
        evidence['github_zip'] = {'archivo':args.github_zip.name, 'pdfs_nombres_y_bytes_iguales':True,
                                  'entradas_duplicadas':False, 'archivos_excluidos':0}
assert before == git('status','--porcelain','-z'), 'La exportacion modifico el arbol de trabajo'
evidence['estado_git_sin_cambios_por_exportacion'] = True
result = json.dumps(evidence, ensure_ascii=False, indent=2) + '\n'
if args.output:
    args.output.write_text(result, encoding='utf-8')
sys.stdout.reconfigure(encoding='utf-8')
print(result, end='')
