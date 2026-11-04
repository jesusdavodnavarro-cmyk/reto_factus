// "Base de datos" de hackathon: una colección guardada en backend/data/<nombre>.json.
// - Se carga al arrancar y se guarda en cada cambio, así `pnpm dev` puede
//   reiniciarse (pasa cada vez que guardas un archivo) sin perder los datos de la demo.
// - Escritura atómica: primero a un .tmp y luego rename, para no dejar el JSON a medias.
// Si después hay tiempo, se cambia por una base de datos real sin tocar los servicios.

import { existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';

const DATA_DIR = resolve('data'); // relativo a donde corres pnpm dev: backend/data

export function createJsonStore<T extends { id: string }>(nombre: string) {
    const file = join(DATA_DIR, `${nombre}.json`);
    const items = new Map<string, T>();

    // Cargar lo que haya en disco
    if (existsSync(file)) {
        for (const item of JSON.parse(readFileSync(file, 'utf8')) as T[]) {
            items.set(item.id, item);
        }
    }

    function save(): void {
        mkdirSync(DATA_DIR, { recursive: true });
        const tmp = `${file}.tmp`;
        writeFileSync(tmp, JSON.stringify([...items.values()], null, 2));
        renameSync(tmp, file);
    }

    return {
        all: (): T[] => [...items.values()],
        get: (id: string): T | undefined => items.get(id),
        count: (): number => items.size,
        insert(item: T): T {
            items.set(item.id, item);
            save();
            return item;
        },
        update(item: T): T {
            items.set(item.id, item);
            save();
            return item;
        },
    };
}
