-- Sample data for development / demo testing
-- Run after 1_schema.sql:
--   psql -U postgres -d roadwatch -f database/2_seed.sql

INSERT INTO complaints (image_url, latitude, longitude, description,
    severity, ai_confidence, detections_count, ai_summary,
    status, assigned_department)
VALUES
(
    '/uploads/sample1.jpg', 28.6139, 77.2090,
    'Large pothole near main junction causing traffic slowdown',
    'High', 0.87, 3,
    'Detected 3 pothole region(s). Largest covers 42.1% of frame, avg confidence 0.87.',
    'Verified', 'Public Works Department'
),
(
    '/uploads/sample2.jpg', 28.6200, 77.2150,
    'Pothole after rain, road partially flooded',
    'Medium', 0.65, 1,
    'Detected 1 pothole region(s). Largest covers 18.5% of frame, avg confidence 0.65.',
    'Assigned', 'Municipal Corporation - Roads Cell'
),
(
    '/uploads/sample3.jpg', 28.6050, 77.2010,
    'Small crack developing near footpath',
    'Low', 0.40, 1,
    'Detected 1 pothole region(s). Largest covers 5.2% of frame, avg confidence 0.40.',
    'Reported', 'Unassigned'
),
(
    '/uploads/sample4.jpg', 28.6300, 77.2250,
    'Multiple potholes on highway stretch',
    'High', 0.91, 5,
    'Detected 5 pothole region(s). Largest covers 55.0% of frame, avg confidence 0.91.',
    'Repair in Progress', 'Traffic & Road Safety Cell'
),
(
    '/uploads/sample5.jpg', 28.5900, 77.1900,
    'Pothole filled temporarily but needs proper repair',
    'Low', 0.38, 1,
    'Detected 1 pothole region(s). Largest covers 4.1% of frame, avg confidence 0.38.',
    'Resolved', 'Public Works Department'
);
