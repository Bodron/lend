const { createHash } = require("node:crypto");
const { spawn, spawnSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const modules = path.join(root, "node_modules");
const marker = path.join(modules, ".pinlend-package-lock.sha256");
const lockHash = createHash("sha256")
  .update(fs.readFileSync(path.join(root, "package-lock.json")))
  .digest("hex");
const installedHash = fs.existsSync(marker) ? fs.readFileSync(marker, "utf8").trim() : "";

if (installedHash !== lockHash || !fs.existsSync(path.join(modules, "next"))) {
  console.log("Installing site dependencies for the current package-lock.json...");
  const install = spawnSync("npm", ["ci"], { cwd: root, stdio: "inherit" });
  if (install.error || install.status !== 0) {
    console.error("Site dependency installation failed.", install.error || install.status);
    process.exit(install.status || 1);
  }
  fs.writeFileSync(marker, `${lockHash}\n`);
}

const app = spawn("npm", ["run", "dev", "--", "--webpack", "--hostname", "0.0.0.0", "--port", "3002"], {
  cwd: root,
  stdio: "inherit",
});
for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => app.kill(signal));
}
app.on("error", (error) => {
  console.error("Could not start the site.", error);
  process.exit(1);
});
app.on("exit", (code) => process.exit(code ?? 1));
