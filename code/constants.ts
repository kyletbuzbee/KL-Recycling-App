
import { MaterialType } from './types';

export const MATERIAL_PRICES: Record<MaterialType, number> = {
  [MaterialType.STEEL]: 0.10,
  [MaterialType.ALUMINUM]: 0.65,
  [MaterialType.COPPER]: 3.50,
  [MaterialType.BRASS]: 2.20,
  [MaterialType.LEAD]: 0.80,
  [MaterialType.STAINLESS_STEEL]: 0.40,
  [MaterialType.OTHER]: 0.05,
  [MaterialType.UNKNOWN]: 0.0,
};

export const VALID_MATERIALS = Object.values(MaterialType).filter(m => m !== MaterialType.UNKNOWN);
