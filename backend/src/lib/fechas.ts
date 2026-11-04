// Fechas como texto YYYY-MM-DD (lo que pide Factus). Sin librerías.

// Hoy en Colombia (no en UTC: a las 8 p. m. en Montería, en UTC ya es mañana)
export function hoyColombia(): string {
    return new Date().toLocaleDateString('en-CA', { timeZone: 'America/Bogota' });
}

// Suma meses sin desbordarse: 31-ene + 1 mes = 28-feb (no 3-mar)
export function sumarMeses(fechaIso: string, meses: number): string {
    const [y, m, d] = fechaIso.split('-').map(Number);
    const destino = new Date(Date.UTC(y, m - 1 + meses, 1));
    const diasDelMes = new Date(Date.UTC(destino.getUTCFullYear(), destino.getUTCMonth() + 1, 0)).getUTCDate();
    destino.setUTCDate(Math.min(d, diasDelMes));
    return destino.toISOString().slice(0, 10);
}
