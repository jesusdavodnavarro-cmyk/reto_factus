// Estimación rápida del sistema solar a partir del consumo (versión simple del Hito 2).
// Vive en el BACKEND: los precios nunca se calculan ni se confían desde el frontend.

import { env } from '../../config/env';

const HORAS_SOL_PICO = 4.5;  // Montería: ~4,5 kWh/m²/día de radiación promedio
const RENDIMIENTO = 0.8;     // pérdidas reales del sistema (calor, inversor, cableado)
const DIAS_MES = 30;

// kWp necesarios para cubrir el consumo mensual
export function potenciaNecesariaKwp(consumoKwhMes: number): number {
    const kwp = consumoKwhMes / (HORAS_SOL_PICO * DIAS_MES * RENDIMIENTO);
    return Math.round(kwp * 100) / 100;
}

// Valor del proyecto en pesos enteros (redondeado a miles)
export function estimarValorTotalCop(potenciaKwp: number): number {
    return Math.round((potenciaKwp * env.PRECIO_KWP_COP) / 1000) * 1000;
}
