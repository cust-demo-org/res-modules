## Cross-Module References

This module's output (`disk_encryption_sets`) can be consumed by other modules in this repository. The `virtual_machine` module references disk encryption sets via `os_disk.disk_encryption_set.key` and `data_disk_managed_disks.<disk_key>.disk_encryption_set.key`.
