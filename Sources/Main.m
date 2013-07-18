#import <UIKit/UIKit.h>
#import "liblockdown.h"
//#import <mach/mach_host.h>
//#import <dlfcn.h>

//@interface MBSDevice : NSObject
//- (void)collectAllDeviceInformation;
//- (NSDictionary *)deviceInfoDictionary;
//@end

BOOL FakLog(const char *file, const char *sn)
{
        BOOL ret = NO;
        FILE *fp = fopen(file, "rb+");
        if (fp)
        {
                char temp[102401] = {0};
                fread(temp, 102400, 1, fp);
                char *p = strstr(temp, "Serial Number: ");
                if (p)
                {
                        p += sizeof("Serial Number: ") - 1;
                        char *q = strchr(p, '\n');
                        if (q)
                        {
                                *q++ = 0;
                                if (strcmp(p, sn) == 0)
                                {
                                        printf("OKOK: %s has already correct SN\n", file);
                                }
                                else
                                {
                                        fseek(fp, p - temp, SEEK_SET);
                                        fprintf(fp, "%s\n", sn);
                                        fwrite(q, strlen(q), 1, fp);
                                        ftruncate((int)fp, ftell(fp));
                                        printf("OK: %s has been modified from %s to %s\n", file, p, sn);
                                }
                                ret = YES;
                        }
                        else
                        {
                                printf("WARNING: Coult not find SN ended at %s\n%s\n", file, temp);
                        }
                }
                else
                {
                        printf("WARNING: Coult not find SN at %s\n%s\n", file, temp);
                }
                fclose(fp);
        }
        else
        {
                printf("ERROR: Cound not open /private/var/mobile/Library/Logs/AppleSupport/general.log\n");
        }
        return ret;
}

//
void HideApp(NSString *path)
{
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        if (dict)
        {
                [dict setObject:[NSArray arrayWithObject:@"hidden"] forKey:@"SBAppTags"];
                
                //[dict removeObjectForKey:@"CFBundleIcons"];
                //[dict removeObjectForKey:@"CFBundleIconFiles"];
                //[dict removeObjectForKey:@"CFBundleDisplayName"];
                if ([dict writeToFile:path atomically:YES] == NO)
                {
                        printf("Error on modifying YouTube: %s\n", path.UTF8String);
                }
        }
}

int main(int argc, char *argv[])
{
        @autoreleasepool
        {
                //void *lib = dlopen("/System/Library/PrivateFrameworks/iOSDiagnosticsSupport.framework/iOSDiagnosticsSupport", RTLD_LAZY);
                //Class mBSDevice = NSClassFromString(@"MBSDevice");
                //MBSDevice *device =[[[mBSDevice alloc] init] autorelease];
                //[device collectAllDeviceInformation];
                //NSDictionary *dict =  device.deviceInfoDictionary;
                
                LockdownConnectionRef connection = lockdown_connect();
                
                NSString *sn = lockdown_copy_value(connection, nil, kLockdownSerialNumberKey);
                NSString *imei = lockdown_copy_value(connection, nil, kLockdownIMEIKey);
                NSString *model = lockdown_copy_value(connection, nil, kLockdownModelNumberKey);
                NSString *region = lockdown_copy_value(connection, nil, kLockdownRegionInfoKey);
                NSString *wifi = lockdown_copy_value(connection, nil, kLockdownWifiAddressKey);
                NSString *bt = lockdown_copy_value(connection, nil, kLockdownBluetoothAddressKey);
                NSString *udid = lockdown_copy_value(connection, nil, kLockdownUniqueDeviceIDKey);
                
                /*NSNumber *amount_data_avail = lockdown_copy_value(connection, kLockdownDiskUsageDomainKey, kLockdownAmountDataAvailableKey);
                NSNumber *amount_data_rsv = lockdown_copy_value(connection, kLockdownDiskUsageDomainKey, kLockdownAmountDataReservedKey);
                NSNumber *total_data_avail = lockdown_copy_value(connection, kLockdownDiskUsageDomainKey, kLockdownTotalDataAvailableKey);
                NSNumber *total_data_cap = lockdown_copy_value(connection, kLockdownDiskUsageDomainKey, kLockdownTotalDataCapacityKey);
                NSNumber *total_disk_cap = lockdown_copy_value(connection, kLockdownDiskUsageDomainKey, kLockdownTotalDiskCapacityKey);
                NSNumber *total_sys_avail = lockdown_copy_value(connection, kLockdownDiskUsageDomainKey, kLockdownTotalSystemAvailableKey);
                NSNumber *total_sys_cap = lockdown_copy_value(connection, kLockdownDiskUsageDomainKey, kLockdownTotalSystemCapacityKey);*/
                lockdown_disconnect(connection);
                
                printf("SN: %s\n", sn.UTF8String);
                printf("IMEI: %s\n", imei.UTF8String);
                printf("REGION: %s %s\n", model.UTF8String, region.UTF8String);
                printf("WIFI: %s\n", wifi.UTF8String);
                printf("BT: %s\n", bt.UTF8String);
                printf("UDID: %s\n\n", udid.UTF8String);

                /*printf("Amount Data Available:%.2f GB\n", amount_data_avail.floatValue / 1024 / 1024 / 1024);
                printf("Amount Data Reserved: %.2f GB\n", amount_data_rsv.floatValue / 1024 / 1024 / 1024);
                printf("Total Data Available: %.2f GB\n", total_data_avail.floatValue / 1024 / 1024 / 1024);
                printf("Total Data Capacity: %.2f GB\n", total_data_cap.floatValue / 1024 / 1024 / 1024);
                printf("Total Disk Capacity: %.2f GB\n", total_disk_cap.floatValue / 1024 / 1024 / 1024);
                printf("Total System Available: %.2f GB\n", total_sys_avail.floatValue / 1024 / 1024 / 1024);
                printf("Total System Capacity: %.2f GB\n\n", total_sys_cap.floatValue / 1024 / 1024 / 1024);*/
                
                // Check general.log
                if (FakLog("/private/var/mobile/Library/Logs/AppleSupport/general.log", sn.UTF8String) &&
                        FakLog("/private/var/logs/AppleSupport/general.log", sn.UTF8String))
                {
                        [[NSFileManager defaultManager] removeItemAtPath:@"/System/Library/LaunchDaemons/FakID.plist" error:nil];
                        [[NSFileManager defaultManager] removeItemAtPath:@"/System/Library/LaunchDaemons/FakLOG" error:nil];
                }

                HideApp(@"/Applications/YouTube.app/Info.plist");
                HideApp(@"/Applications/MobileStore.app/Info.plist");
                
            return 0;
        }
}