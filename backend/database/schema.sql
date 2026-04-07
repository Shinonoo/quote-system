-- Greentech Quote Database Schema
-- Run this to set up the database

CREATE DATABASE IF NOT EXISTS greentech_quote;
USE greentech_quote;

-- Users table for authentication
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    prefix VARCHAR(10) DEFAULT 'GT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Equipment types (products)
CREATE TABLE IF NOT EXISTS equipment_types (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    base_divisor DECIMAL(10, 2) NOT NULL DEFAULT 144,
    base_multiplier DECIMAL(10, 2) NOT NULL DEFAULT 3800,
    final_multiplier DECIMAL(10, 2) NOT NULL DEFAULT 1.0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customizations available for equipment
CREATE TABLE IF NOT EXISTS customizations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    key_name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    type ENUM('multiplier', 'fixed') DEFAULT 'multiplier',
    default_value DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Link equipment types to their allowed customizations
CREATE TABLE IF NOT EXISTS equipment_customizations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    equipment_type_id INT NOT NULL,
    customization_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (equipment_type_id) REFERENCES equipment_types(id) ON DELETE CASCADE,
    FOREIGN KEY (customization_id) REFERENCES customizations(id) ON DELETE CASCADE,
    UNIQUE KEY unique_equipment_customization (equipment_type_id, customization_id)
);

-- Quotations (main quote header)
CREATE TABLE IF NOT EXISTS quotations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quote_no VARCHAR(50) NOT NULL UNIQUE,
    reference_no VARCHAR(50) NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    company_location VARCHAR(255),
    attention_name VARCHAR(100),
    attention_position VARCHAR(100),
    customer_project VARCHAR(100) NOT NULL,
    project_location VARCHAR(255),
    grand_total DECIMAL(15, 2) NOT NULL DEFAULT 0,
    status ENUM('pending', 'approved', 'rejected', 'expired') DEFAULT 'pending',
    created_by INT,
    quote_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Quotation items (line items)
CREATE TABLE IF NOT EXISTS quotation_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quotation_id INT NOT NULL,
    item_no INT NOT NULL,
    description TEXT NOT NULL,
    item_code VARCHAR(50),
    length DECIMAL(10, 2),
    width DECIMAL(10, 2),
    customizations JSON,
    raw_unit_price DECIMAL(15, 2) NOT NULL,
    discount_type ENUM('none', 'percentage', 'fixed') DEFAULT 'none',
    discount_value DECIMAL(15, 2) DEFAULT 0,
    final_unit_price DECIMAL(15, 2) NOT NULL,
    qty INT NOT NULL DEFAULT 1,
    line_total DECIMAL(15, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (quotation_id) REFERENCES quotations(id) ON DELETE CASCADE
);

-- Insert default customizations
INSERT INTO customizations (key_name, display_name, type, default_value) VALUES
('insect_screen', 'Insect Screen', 'multiplier', 1.15),
('bird_screen', 'Bird Screen', 'multiplier', 1.20),
('obvd', 'OBVD (Opposed Blade Volume Damper)', 'multiplier', 1.25),
('radial_damper', 'Radial Damper', 'multiplier', 1.30),
('double_frame', 'Double Frame', 'multiplier', 1.40),
('powder_coat', 'Powder Coating', 'fixed', 500),
('acrylic', 'Acrylic', 'multiplier', 1.10)
ON DUPLICATE KEY UPDATE key_name = key_name;

-- Insert equipment types (Air Terminals, Grilles, Diffusers, Louvers)
INSERT INTO equipment_types (code, name, category, base_divisor, base_multiplier, final_multiplier, description) VALUES
-- Air Grilles
('S-AG', 'Single Deflection Air Grille (Aluminum)', 'Air Grille', 144, 3800, 1.0, 'Standard single deflection air grille made of aluminum'),
('D-AG', 'Double Deflection Air Grille (Aluminum)', 'Air Grille', 144, 4200, 1.0, 'Double deflection air grille for better air distribution'),
('L-AG', 'Linear Bar Air Grille (Aluminum)', 'Air Grille', 144, 4500, 1.0, 'Linear bar grille for architectural applications'),
('S-AD', 'Single Deflection Air Grille (GI)', 'Air Grille', 144, 3200, 1.0, 'Single deflection air grille made of galvanized iron'),
('D-AD', 'Double Deflection Air Grille (GI)', 'Air Grille', 144, 3600, 1.0, 'Double deflection air grille made of galvanized iron'),
('SAG-SD', 'Single Deflection Air Grille - Movable Blade', 'Air Grille', 144, 3800, 1.0, 'Single deflection air grille with movable blade. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs'),
('SAG-DD', 'Double Deflection Air Grille - Movable Blade', 'Air Grille', 144, 4200, 1.0, 'Double deflection air grille with movable blade for better air distribution. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs'),
('LBG-A', 'Linear Bar Grille - Horizontal Blade (Fixed)', 'Air Grille', 144, 4500, 1.0, 'Linear bar grille with horizontal fixed blade for architectural applications. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs'),

-- Return Air
('RS', 'Return Air Grille (Egg Crate)', 'Return Air', 144, 2800, 1.0, 'Egg crate return air grille'),

-- Diffusers
('FD', 'Floor Diffuser', 'Diffuser', 144, 5500, 1.0, 'Floor mounted diffuser'),
('SD', 'Slot Diffuser', 'Diffuser', 144, 6500, 1.0, 'Linear slot diffuser'),
('RD', 'Round Diffuser', 'Diffuser', 1, 2500, 1.0, 'Round ceiling diffuser (per piece)'),
('SCD', 'Ceiling Diffuser; 4-Way', 'Diffuser', 1, 3500, 1.0, 'Square ceiling diffuser with 4-way air pattern. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs'),
('RCD', 'Round Ceiling Diffuser; 4-Way', 'Diffuser', 1, 2800, 1.0, 'Round ceiling diffuser with 4-way air pattern. Material: AL - Aluminum only. Unit: pcs'),

-- VAV
('VV', 'Variable Volume Unit', 'VAV', 1, 15000, 1.0, 'Variable air volume unit (per piece)'),

-- Dampers
('FD-BC', 'Fire Damper (Butterfly Type)', 'Damper', 1, 3500, 1.0, 'Butterfly type fire damper (per piece)'),
('VD', 'Volume Control Damper', 'Damper', 144, 1800, 1.0, 'Volume control damper with opposed blades'),

-- Accessories
('FLEX', 'Flexible Duct Connector', 'Accessories', 1, 450, 1.0, 'Flexible duct connector (per meter)'),

-- Louvers
('SG', 'Sand Trap Louver', 'Louver', 144, 5200, 1.0, 'Sand trap louver for fresh air intake'),
('AL-45', 'Air Louver- Z Type Blade (Fixed) (Outdoor Type)', 'Louver', 144, 4800, 1.0, 'Z-type blade air louver for outdoor use with 45mm blade spacing. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs'),
('AL-75', 'Air Louver- Z Type Blade (Fixed) (Outdoor Type)', 'Louver', 144, 5200, 1.0, 'Z-type blade air louver for outdoor use with 75mm blade spacing. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs'),
('WAL-75', 'Air Louver- Z Type Blade (Fixed) (Weatherproof)', 'Louver', 144, 5800, 1.0, 'Weatherproof Z-type blade air louver with 75mm blade spacing. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs'),
('GL-OBB', 'Louver Grille - 45degrees Fixed Blade', 'Louver', 144, 4000, 1.0, 'Louver grille with 45-degree fixed blade. Materials: AL - Aluminum, GI - Galvanized Iron. Unit: pcs')
ON DUPLICATE KEY UPDATE code = code;

-- Link equipment to customizations
-- Standard air grilles and return air products get standard customizations
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.category IN ('Air Grille', 'Return Air') 
  AND e.code NOT IN ('SAG-SD', 'SAG-DD', 'LBG-A')
  AND c.key_name IN ('insect_screen', 'bird_screen', 'obvd', 'powder_coat')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- SCD (Ceiling Diffuser 4-Way): obvd/bird/insect/powder/acrylic
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

-- RCD (Round Ceiling Diffuser): radial_damper/bird/insect only (no powder/acrylic)
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.code = 'RCD' AND c.key_name IN ('radial_damper', 'bird_screen', 'insect_screen')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- Standard diffusers (not SCD, RCD): standard customizations
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.category = 'Diffuser' 
  AND e.code NOT IN ('SCD', 'RCD')
  AND c.key_name IN ('insect_screen', 'bird_screen', 'powder_coat')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;

-- Louvers: bird/insect/powder/acrylic
INSERT INTO equipment_customizations (equipment_type_id, customization_id)
SELECT e.id, c.id 
FROM equipment_types e
CROSS JOIN customizations c
WHERE e.category = 'Louver' 
  AND c.key_name IN ('bird_screen', 'insect_screen', 'powder_coat', 'acrylic')
ON DUPLICATE KEY UPDATE equipment_type_id = equipment_type_id;
