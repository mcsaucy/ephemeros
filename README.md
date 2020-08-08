# Ephemeros

Tools and configuration for provisioning OS diskless Container Linux clusters,
running [k3s](https://k3s.io) and logging with
[Papertrail](https://papertrail.com). Nodes boot from an iPXE flash drive,
which also contains a dedicated volume for keeping secrets.

The iPXE script downloads and boots the newest stable release for Flatcar
Container Linux (RIP CoreOS), which then pulls in the
[ignition.ign](ignition.ign) file in this repo.

Since that is publicly visible, we cannot have any secrets kicking around in
there. But we still need those values to be carried over somehow, so we capture
those values at iPXE flash drive provisioning-time and throw them into the
`secrets` volume. From there, all service definitions pull what they need from
`/secrets`, which is readonly mounted.

## Making boot media

Pop in a flash drive you don't care about and then run the following:

```shell
sudo \
    PAPERTRAIL_HOST=logsX.papertrailapp.com PAPERTRAIL_PORT=XXXXX \
    K3S_TOKEN="you should really set this to something secret" \
    # Other K3S_* env vars you probably want to set \
    ./build_pxe_stick.sh /dev/sdX
```

## Updating the Ignition configs

The [ignition.ign](ignition.ign) file is generated from the
[ignition.yml](ignition.yml) file. You can perform that tranformation with
the following:

```shell
bash ./ignite.sh ignition.yml > ignition.ign
```

Note that the ignition config is pulled down from github each boot, so you'll
need to push any changes in order to test them. There's likely some room here
for certain iPXE values (such as the ignition config URI) to be derived from
the git repo itself...

## Testing with qemu

You can have qemu boot the flash drive for testing purposes. Note that this
will result in downloading several hundred megabytes each run. I've been using
the following:

```shell
sudo qemu-system-x86_64 \
    -hda /dev/sdX \
    -smp 2 -m 4096 \
    --curses \
    -net nic,model=virtio -net user,hostfwd=tcp::2222-:22
```

If you get stuck in the console, then alt-2 and then `quit` should get you out.
You can also flip `--curses` to `--vga virtio` if you want your console in a
dedicated graphical window rather than a terminal.

Then you can just `ssh core@localhost -p 2222`.

## I wanna mess with this

Cool! A lot of things are hardcoded to `mcsaucy` presently and you're gonna
want to fix those. You're going to want to replace every instance of `mcsaucy`
with a more appropriate value for your setup. You're also going to want to sub
out my ssh public key in the ignition file for you own.
