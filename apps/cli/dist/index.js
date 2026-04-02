import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createCli } from '@dotfiles/cli-engine';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, '../../..');
async function run() {
    const program = await createCli(rootDir);
    program.parse();
}
run();
//# sourceMappingURL=index.js.map