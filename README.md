# initrd-repack

This script will extract the given initrd and archive into a temp directory and repack the merged content to a new initrd.

## Why?

Sometimes kernel modules are missing and you can't install your system due to a missing raid controller or network interface.
You need to add the kernel-modules to the initrd and repack it to get it working during the installation.

## example

```
./initrd-repack.sh -i boot.img.gz -a linux-image-extra-4.13.0-36-generic_4.13.0-36.40_amd64.deb
```

## License

[LICENSE](./LICENSE)
