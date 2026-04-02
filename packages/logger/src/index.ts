import pc from 'picocolors';

export const logger = {
  info: (msg: string) => console.log(`${pc.blue('ℹ')} ${msg}`),
  success: (msg: string) => console.log(`${pc.green('✔')} ${msg}`),
  warning: (msg: string) => console.log(`${pc.yellow('⚠')} ${msg}`),
  error: (msg: string) => console.log(`${pc.red('✖')} ${msg}`),
  step: (msg: string) => console.log(`${pc.cyan('➜')} ${msg}`),
  dim: (msg: string) => console.log(pc.dim(msg)),
};
