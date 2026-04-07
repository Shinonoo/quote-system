-- Update Products Script
-- Run this to update equipment types with the new product specifications

USE greentech_quote;

-- ============================================
-- 1. Add new customizations
-- ============================================
INSERT INTO customizations (key_name, display_name, type, default_value) VALUES
('acrylic', 'Acrylic', 'multiplier', 1.10)
ON DUPLICATE KEY UPDATE key_name = key_name;

-- ============================================
-- 2. Update/Insert Equipment Types with proper categorization
-- ============================================

-- Ceiling Diffuser 4-Way (SCD)
INSERT INTO equipment_types (code, name, category, base_divisor, base_multiplier, final_multiplier, description) VALUES
('SCD', 'Ceiling Diffuser; 4-Way', 'Diffuser', 1, 3500, 1.0, 'Square ceiling diffuser with 4-way air pattern. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs')
ON DUPLICATE KEY UPDATE 
  name = VALUES(name),
  description = VALUES(description),
  category = VALUES(category);

-- Single Deflection Air Grille - Movable Blade (SAG-SD)
INSERT INTO equipment_types (code, name, category, base_divisor, base_multiplier, final_multiplier, description) VALUES
('SAG-SD', 'Single Deflection Air Grille - Movable Blade', 'Air Grille', 144, 3800, 1.0, 'Single deflection air grille with movable blade. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs')
ON DUPLICATE KEY UPDATE 
  name = VALUES(name),
  description = VALUES(description),
  category = VALUES(category);

-- Double Deflection Air Grille - Movable Blade (SAG-DD)
INSERT INTO equipment_types (code, name, category, base_divisor, base_multiplier, final_multiplier, description) VALUES
('SAG-DD', 'Double Deflection Air Grille - Movable Blade', 'Air Grille', 144, 4200, 1.0, 'Double deflection air grille with movable blade for better air distribution. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs')
ON DUPLICATE KEY UPDATE 
  name = VALUES(name),
  description = VALUES(description),
  category = VALUES(category);

-- Linear Bar Grille - Horizontal Blade Fixed (LBG-A)
INSERT INTO equipment_types (code, name, category, base_divisor, base_multiplier, final_multiplier, description) VALUES
('LBG-A', 'Linear Bar Grille - Horizontal Blade (Fixed)', 'Air Grille', 144, 4500, 1.0, 'Linear bar grille with horizontal fixed blade for architectural applications. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs')
ON DUPLICATE KEY UPDATE 
  name = VALUES(name),
  description = VALUES(description),
  category = VALUES(category);

-- Round Ceiling Diffuser 4-Way (RCD) - aluminum only
INSERT INTO equipment_types (code, name, category, base_divisor, base_multiplier, final_multiplier, description) VALUES
('RCD', 'Round Ceiling Diffuser; 4-Way', 'Diffuser', 1, 2800, 1.0, 'Round ceiling diffuser with 4-way air pattern. Material: AL - Aluminum only. Unit: pcs')
ON DUPLICATE KEY UPDATE 
  name = VALUES(name),
  description = VALUES(description),
  category = VALUES(category);

-- Air Louver Z Type Blade Fixed Outdoor Type (AL-45)
INSERT INTO equipment_types (code, name, category, base_divisor, base_multiplier, final_multiplier, description) VALUES
('AL-45', 'Air Louver- Z Type Blade (Fixed) (Outdoor Type)', 'Louver', 144, 4800, 1.0, 'Z-type blade air louver for outdoor use with 45mm blade spacing. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs')
ON DUPLICATE KEY UPDATE 
  name = VALUES(name),
  description = VALUES(description),
  category = VALUES(category);

-- Air Louver Z Type Blade Fixed Outdoor Type (AL-75)
INSERT INTO equipment_types (code, name, category, base_divisor, base_multiplier, final_multiplier, description) VALUES
('AL-75', 'Air Louver- Z Type Blade (Fixed) (Outdoor Type)', 'Louver', 144, 5200, 1.0, 'Z-type blade air louver for outdoor use with 75mm blade spacing. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs')
ON DUPLICATE KEY UPDATE 
  name = VALUES(name),
  description = VALUES(description),
  category = VALUES(category);

-- Air Louver Z Type Blade Fixed Weatherproof (WAL-75)
INSERT INTO equipment_types (code, name, category, base_divisor, base_multiplier, final_multiplier, description) VALUES
('WAL-75', 'Air Louver- Z Type Blade (Fixed) (Weatherproof)', 'Louver', 144, 5800, 1.0, 'Weatherproof Z-type blade air louver with 75mm blade spacing. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs')
ON DUPLICATE KEY UPDATE 
  name = VALUES(name),
  description = VALUES(description),
  category = VALUES(category);

-- Louver Grille 45degrees Fixed Blade (GL + obb)
INSERT INTO equipment_types (code, name, category, base_divisor, base_multiplier, final_multiplier, description) VALUES
('GL-OBB', 'Louver Grille - 45degrees Fixed Blade', 'Louver', 144, 4000, 1.0, 'Louver grille with 45-degree fixed blade. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs')
ON DUPLICATE KEY UPDATE 
  name = VALUES(name),
  description = VALUES(description),
  category = VALUES(category);

-- ============================================
-- 3. Link Equipment to Customizations
-- ============================================

-- SCD: obvd/bird/insect/powder/acrylic
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.code = 'SCD' AND c.key_name IN ('obvd', 'bird_screen', 'insect_screen', 'powder_coat', 'acrylic')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- SAG-SD: obvd/bird/insect/powder/acrylic
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.code = 'SAG-SD' AND c.key_name IN ('obvd', 'bird_screen', 'insect_screen', 'powder_coat', 'acrylic')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- SAG-DD: obvd/bird/insect/powder/acrylic
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.code = 'SAG-DD' AND c.key_name IN ('obvd', 'bird_screen', 'insect_screen', 'powder_coat', 'acrylic')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- LBG-A: obvd/bird/insect/powder/acrylic
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.code = 'LBG-A' AND c.key_name IN ('obvd', 'bird_screen', 'insect_screen', 'powder_coat', 'acrylic')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- RCD: radial_damper/bird/insect (no powder/acrylic for round diffusers)
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.code = 'RCD' AND c.key_name IN ('radial_damper', 'bird_screen', 'insect_screen')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- AL-45: bird/insect/powder/acrylic
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.code = 'AL-45' AND c.key_name IN ('bird_screen', 'insect_screen', 'powder_coat', 'acrylic')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- AL-75: bird/insect/powder/acrylic
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.code = 'AL-75' AND c.key_name IN ('bird_screen', 'insect_screen', 'powder_coat', 'acrylic')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- WAL-75: bird/insect/powder/acrylic
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.code = 'WAL-75' AND c.key_name IN ('bird_screen', 'insect_screen', 'powder_coat', 'acrylic')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- GL-OBB: bird/insect/powder/acrylic
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.code = 'GL-OBB' AND c.key_name IN ('bird_screen', 'insect_screen', 'powder_coat', 'acrylic')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- ============================================
-- Verify the updates
-- ============================================
SELECT 
  e.code,
  e.name,
  e.category,
  e.description,
  GROUP_CONCAT(c.key_name ORDER BY c.key_name) as available_customizations
FROM equipment_types e
LEFT JOIN equipment_customizations ec ON e.id = ec.equipment_type_id
LEFT JOIN customizations c ON ec.customization_id = c.id
WHERE e.code IN ('SCD', 'SAG-SD', 'SAG-DD', 'LBG-A', 'RCD', 'AL-45', 'AL-75', 'WAL-75', 'GL-OBB')
GROUP BY e.id
ORDER BY e.category, e.code;
