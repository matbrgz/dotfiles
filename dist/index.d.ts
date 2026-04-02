export type PackageManagerName = 'apt' | 'pacman' | 'dnf' | 'zypper' | 'brew' | 'choco' | 'unknown';
export declare abstract class PackageManager {
    abstract name: PackageManagerName;
    abstract isInstalled(packageName: string): Promise<boolean>;
    abstract install(packageName: string): Promise<{
        success: boolean;
        stdout?: string;
        stderr?: string;
    }>;
}
export declare class AptManager extends PackageManager {
    name: PackageManagerName;
    isInstalled(packageName: string): Promise<boolean>;
    install(packageName: string): Promise<{
        success: boolean;
        stdout: string;
        stderr: string;
    } | {
        success: boolean;
        stderr: any;
        stdout?: undefined;
    }>;
}
export declare class ChocoManager extends PackageManager {
    name: PackageManagerName;
    isInstalled(packageName: string): Promise<boolean>;
    install(packageName: string): Promise<{
        success: boolean;
        stdout: string;
        stderr: string;
    } | {
        success: boolean;
        stderr: any;
        stdout?: undefined;
    }>;
}
export declare function getNativeManager(): PackageManager | null;
