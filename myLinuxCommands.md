| Command    | Mnemonic/Meaning                   | Description                                                          | Topic                                 |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **cd**     | Change Directory                   | Moves you into a different directory.                                | Navigating                          |
| **ls**     | List                               | Displays the contents of a directory.                                | Navigating                          |
| **pwd**    | Print Working Directory            | Shows your current directory path.                                   | Navigating                          |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **mkdir**  | Make Directory                     | Creates a new folder/directory.                                      | File & Directory Manipulation       |
| **rmdir**  | Remove Directory                   | Deletes an empty directory.                                          | File & Directory Manipulation       |
| **touch**  | Touch                              | Creates an empty file or updates its timestamp.                      | File & Directory Manipulation       |
| **rm**     | Remove                             | Deletes files or directories.                                        | File & Directory Manipulation       |
| **cp**     | Copy                               | Copies files or directories.                                         | File & Directory Manipulation       |
| **mv**     | Move                               | Moves or renames files/directories.                                  | File & Directory Manipulation       |
| **ln**     | Link                               | Creates hard or symbolic links between files.                        | File & Directory Manipulation       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **cat**    | Concatenate                        | Displays file content or concatenates files.                         | Text Viewing & Editing              |
| **head**   | Head                               | Shows the first few lines of a file.                                 | Text Viewing & Editing              |
| **tail**   | Tail                               | Shows the last few lines of a file.                                  | Text Viewing & Editing              |
| **nano**   | Nano Editor                        | A simple, user-friendly text editor.                                 | Text Viewing & Editing              |
| **vim**    | Vi IMproved                        | A powerful, advanced text editor.                                    | Text Viewing & Editing              |
| **less**   | Less                               | Interactively views file contents.                                   | Text Viewing & Editing              |
| **more**   | More                               | Views file contents page by page.                                    | Text Viewing & Editing              |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **grep**   | Global Regular Expression Print    | Searches text for patterns.                                          | Searching & Pattern Matching        |
| **find**   | Find                               | Searches for files in a directory hierarchy.                         | Searching & Pattern Matching        |
| **locate** | Locate                             | Quickly finds files by name using a prebuilt database.               | Searching & Pattern Matching        |
| **awk**    | Awk                                | A powerful text-processing language for pattern scanning.            | Searching & Pattern Matching        |
| **sed**    | Stream Editor                      | Filters and transforms text in a stream.                             | Searching & Pattern Matching        |
| **diff**   | Difference                         | Compares files line by line.                                         | Searching & Pattern Matching        |
| **sort**   | Sort                               | Sorts lines of text.                                                 | Searching & Pattern Matching        |
| **uniq**   | Unique                             | Filters out repeated lines.                                          | Searching & Pattern Matching        |
| **wc**     | Word Count                         | Counts lines, words, and characters in text.                         | Searching & Pattern Matching        |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **chmod**  | Change Mode                        | Modifies file permissions.                                           | Permissions & Ownership             |
| **chown**  | Change Owner                       | Changes the file's owner and group.                                  | Permissions & Ownership             |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **df**     | Disk Free                          | Reports filesystem disk space usage.                                 | Disk/Filesystem & Storage           |
| **du**     | Disk Usage                         | Estimates file/directory space usage.                                | Disk/Filesystem & Storage           |
| **mount**  | Mount                              | Attaches a filesystem to a directory.                                | Disk/Filesystem & Storage           |
| **umount** | Unmount                            | Detaches a mounted filesystem.                                       | Disk/Filesystem & Storage           |
| **lsblk**  | List Block Devices                 | Displays block devices in a tree-like format.                        | Disk/Filesystem & Storage           |
| **blkid**  | Block Identifier                   | Prints attributes of block devices.                                  | Disk/Filesystem & Storage           |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **ps**     | Process Status                     | Lists current active processes.                                      | Process Management & Monitoring     |
| **kill**   | Kill                               | Terminates a process by its PID.                                     | Process Management & Monitoring     |
| **top**    | Top                                | Provides real-time process monitoring.                               | Process Management & Monitoring     |
| **htop**   | Htop                               | An enhanced, interactive process monitor.                            | Process Management & Monitoring     |
| **free**   | Free                               | Displays system memory usage.                                        | Process Management & Monitoring     |
| **uptime** | Up Time                            | Shows how long the system has been running.                          | Process Management & Monitoring     |
| **dmesg**  | D Message                          | Prints kernel ring buffer messages.                                  | Process Management & Monitoring     |
| **systemctl** | System Control                  | Manages systemd services and system state.                           | Process Management & Monitoring     |
| **journalctl** | Journal Control                | Queries and displays systemd logs.                                   | Process Management & Monitoring     |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **uname**  | Unix Name                          | Displays kernel and system information.                              | System Information                  |
| **lscpu**  | List CPU                           | Shows CPU architecture information.                                  | System Information                  |
| **lsusb**  | List USB                           | Displays information about USB devices.                              | System Information                  |
| **lspci**  | List PCI                           | Lists all PCI devices.                                                 | System Information                  |
| **dmidecode** | DMI Decode                      | Extracts hardware information from the BIOS.                         | System Information                  |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **ifconfig** | Interface Config                 | Displays/configures network interfaces (legacy tool).                | Networking                          |
| **ip**     | IP                                 | Manages network interfaces, routes, and tunnels.                     | Networking                          |
| **netstat**| Network Statistics                 | Displays network connections and routing tables.                     | Networking                          |
| **ss**     | Socket Statistics                  | Provides detailed socket information (faster than netstat).           | Networking                          |
| **ping**   | Ping                               | Tests connectivity by sending ICMP echo requests.                    | Networking                          |
| **traceroute** | Trace Route                   | Traces the network path to a remote host.                            | Networking                          |
| **wget**   | Web Get                            | Downloads files from the web non-interactively.                      | Networking                          |
| **curl**   | Client URL                         | Transfers data with URL syntax.                                      | Networking                          |
| **ssh**    | Secure Shell                       | Securely connects to remote systems via encryption.                  | Networking                          |
| **scp**    | Secure Copy                        | Securely copies files between hosts over SSH.                        | Networking                          |
| **rsync**  | Remote Sync                        | Efficiently synchronizes files/directories between locations.        | Networking                          |
| **dig**    | Domain Information Groper          | Performs DNS lookups.                                                | Networking                          |
| **host**   | Host                               | A simple DNS lookup utility.                                         | Networking                          |
| **whois**  | Who Is                             | Queries domain registration and WHOIS information.                   | Networking                          |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **tar**    | Tape Archive                       | Combines multiple files into one archive.                            | Archiving & Compression             |
| **gzip**   | GNU Zip                            | Compresses files using the gzip algorithm.                           | Archiving & Compression             |
| **gunzip** | GNU Unzip                          | Decompresses files compressed with gzip.                             | Archiving & Compression             |
| **zip**    | Zip                                | Creates a ZIP archive of files.                                      | Archiving & Compression             |
| **unzip**  | Unzip                              | Extracts files from a ZIP archive.                                   | Archiving & Compression             |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **echo**   | Echo                               | Outputs text or variables to the terminal.                           | Shell Environment & History         |
| **history**| History                            | Displays a list of previously executed commands.                     | Shell Environment & History         |
| **alias**  | Alias                              | Creates shortcuts or alternate names for commands.                   | Shell Environment & History         |
| **env**    | Environment                        | Displays environment variables.                                      | Shell Environment & History         |
| **export** | Export                             | Sets environment variables for child processes.                      | Shell Environment & History         |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **iptables** | IP Tables                        | Configures IPv4 firewall rules.                                      | Security & Forensics                |
| **tcpdump**| TCP Dump                           | Captures and displays network packets.                               | Security & Forensics                |
| **nmap**   | Network Mapper                     | Scans networks for hosts and services.                               | Security & Forensics                |
| **strace** | System Trace                       | Traces system calls and signals of a process.                        | Security & Forensics                |
| **lsof**   | List Open Files                    | Lists open files and the processes using them.                       | Security & Forensics                |
| **nc**     | Netcat                             | Reads/writes data across network connections (“Swiss Army knife”).     | Security & Forensics                |
| **socat**  | SOcket CAT                         | Relays bidirectional data between two endpoints.                     | Security & Forensics                |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **cron**   | Cron                               | Daemon that executes scheduled tasks.                                | Scheduling & Cron Jobs              |
| **crontab**| Cron Table                         | Edits or lists the table of scheduled jobs.                          | Scheduling & Cron Jobs              |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **man**    | Manual                             | Displays the manual (documentation) for commands.                    | System Control                      |
| **date**   | Date                               | Displays or sets the system date and time.                           | System Control                      |
| **clear**  | Clear                              | Clears the terminal screen.                                          | System Control                      |
| **reboot** | Reboot                             | Restarts the system.                                                 | System Control                      |
| **shutdown**| Shutdown                          | Shuts down or restarts the system.                                   | System Control                      |
| **whoami** | Who Am I                           | Displays the current user.                                           | System Control                      |
