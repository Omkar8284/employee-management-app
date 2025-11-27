const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// Database Connection
const db = mysql.createConnection({
    host: "localhost",
    user: "omkar",
    password: "omkar123",
    database: "emsdb"
});

// Create table if not exists
db.query(`
    CREATE TABLE IF NOT EXISTS employees (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100),
        role VARCHAR(100)
    )
`);

// POST - Add employee
app.post("/employee", (req, res) => {
    const { name, role } = req.body;
    db.query("INSERT INTO employees (name, role) VALUES (?, ?)", [name, role], (err) => {
        if (err) return res.json({ error: err });
        res.json({ message: "Employee Added" });
    });
});

// GET - List employees
app.get("/employees", (req, res) => {
    db.query("SELECT * FROM employees", (err, result) => {
        if (err) return res.json({ error: err });
        res.json(result);
    });
});

// Backend will run on port 3001
app.listen(3001, () => console.log("Backend running on port 3001"));
