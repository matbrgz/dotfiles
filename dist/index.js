"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChocoManager = exports.AptManager = exports.PackageManager = void 0;
exports.getNativeManager = getNativeManager;
const node_child_process_1 = require("node:child_process");
const node_util_1 = require("node:util");
const core_1 = require("@dotfiles/core");
const execAsync = (0, node_util_1.promisify)(node_child_process_1.exec);
class PackageManager {
}
exports.PackageManager = PackageManager;
class AptManager extends PackageManager {
    name = 'apt';
    async isInstalled(packageName) {
        try {
            await execAsync(`dpkg -l | grep -qw ${packageName}`);
            return true;
        }
        catch {
            return false;
        }
    }
    async install(packageName) {
        try {
            const { stdout, stderr } = await execAsync(`sudo apt install -y ${packageName}`);
            return { success: true, stdout, stderr };
        }
        catch (e) {
            return { success: false, stderr: e.message };
        }
    }
}
exports.AptManager = AptManager;
class ChocoManager extends PackageManager {
    name = 'choco';
    async isInstalled(packageName) {
        try {
            await execAsync(`choco list --local-only ${packageName} | findstr /i ${packageName}`);
            return true;
        }
        catch {
            return false;
        }
    }
    async install(packageName) {
        try {
            const { stdout, stderr } = await execAsync(`choco install -y ${packageName}`);
            return { success: true, stdout, stderr };
        }
        catch (e) {
            return { success: false, stderr: e.message };
        }
    }
}
exports.ChocoManager = ChocoManager;
function getNativeManager() {
    const os = (0, core_1.detectOS)();
    if (os === 'linux' || os === 'wsl')
        return new AptManager(); // Defaulting to apt for now, can be improved
    if (os === 'windows')
        return new ChocoManager();
    return null;
}
//# sourceMappingURL=index.js.map