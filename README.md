# DynDNS with Cloudflare

DynDNS is a bash-based program that performs dynamic DNS updates via the Cloudflare API. It checks the current public IP address of the server and automatically updates it on the specified DynDNS domain when it changes.

## Features

- Automatic detection of the public IP address.
- Updating DNS records via the Cloudflare API.
- Configurable via a flexible `etc/Config.inc.sh`.
- Support of environment variables for the runtime override of configuration values.
- Encryption of the Cloudflare token with a user-defined key.
- Support for e-mail notifications of successes and errors.
- Storage of the last set IP address to minimize unnecessary API calls.
- Extendable and modular design.

## Requirements

- **Bash 4.2+**
- **curl**
- **jq**
- **base64**
- **perl**
- **mail** (with support for HTML and UTF-8)
- **Cloudflare API Token** with sufficient authorizations for DNS entries.

## Installation

1. Copy the program to `/usr/local/share/dyndns`.
    ```bash
    sudo cp -r dyndns /usr/local/share/dyndns
    ```
2. Make sure that the scripts are executable.
    ```bash
    chmod +x /usr/local/share/dyndns/bin/dyndns.sh
    ```

## Configuration

The configuration file can be found under `etc/Config.inc.sh`. You can adjust the values directly in the file or overwrite them at runtime using environment variables.

### Configuration example

The variable $cwd is determined at runtime and is the absolute path to the program directory `/usr/local/share/dyndns`.

```bash
cfg[logfile]="${cwd}/log/dyndns.log"
cfg[cloudflare_apiurl]="https://api.cloudflare.com/client/v4"
cfg[cloudflare_token]="<verschlüsseltes Token>"
cfg[dyndns_domain]="example.com"
cfg[notify_recipient]="admin@example.com"
cfg[notify_onsuccess]="Yes"
```

## Encryption of the Cloudflare token

Encrypt your token

```bash
/usr/local/share/dyndns/bin/dyndns.sh <TOKEN>
```

Add the encrypted token to the configuration file

```bash
cfg[cloudflare_token]="<verschlüsseltes Token>"
```

## DynDNS-Update

The main script `bin/dyndns.sh` is normally executed by cronjob every 5 minutes.

```bash
*/5 * * * * /usr/local/share/dyndns/bin/dyndns.sh
```

## Display help

```bash
/usr/local/share/dyndns/bin/dyndns.sh -h
Usage: /usr/local/share/dyndns/bin/dyndns.sh [OPTIONS] <TOKEN>

Options:
  -h, --help            Show this help message and exit.
  <TOKEN>               Encrypts the provided TOKEN for use in cfg[cloudflare_token].

Examples:
  bin/dyndns.sh -h                 Show the help message.
  bin/dyndns.sh myToken123         Encrypt 'myToken123' and output the encrypted string.


```

## Logs

In the long run, you should consider including this file in the OS log rotation or change the path to the global log directory to have it automatically rotated by the OS.

- **Log file** `log/dyndns.log`
- **Last IP address** `log/lastipaddr.dat`

## Error notification

In the event of errors, the program sends an e-mail to the address specified in the configuration. The e-mail contains.

- The error message.
- The last log entries (number controllable via `cfg[nofify_logtrace_count]`).

Optional notifications for successful updates can be controlled via `cfg[notify_onsuccess]`.

## Expandability

The program consists of several modular scripts.

- `bin/dyndns.sh`: Main script for updates.
- `etc/Config.inc.sh`: Configuration.
- `lib/Bootstrap.inc.sh`: Initialization and loading of classes.
- `lib/Cloudflare.class.sh`: Methods for Cloudflare API interaction.
- `lib/Crypto.class.sh`: Encryption and decryption.
- `lib/DynDNS.inc.sh`: actual program library which contains the logic.
- `lib/Logger.class.sh`: Logging mechanisms.

## Notes

- Make sure that the TTL of the DNS entries is set to a maximum of 300 seconds (5 minutes) to ensure prompt updates.
- If necessary, change the encryption key `CRYPTOKEY` in `lib/Bootstrap.inc.sh` and encrypt the token again.

## Additional

I have built a Debian package from the script. The Debian/Ubuntu repository can be found at [https://deb.tuxnet24.de/](https://deb.tuxnet24.de/).

## 
## Author

**Marko Schulz** <[info@tuxnet24.de](mailto:info@tuxnet24.de)>
