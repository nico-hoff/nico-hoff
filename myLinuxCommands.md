# Navigating
| Command    | Mnemonic/Meaning                   | Description                                                          
|------------|------------------------------------|----------------------------------------------------------------------
| **cd**     | Change Directory                   | Moves you into a different directory.                                
| **ls**     | List                               | Displays the contents of a directory.                                
| **pwd**    | Print Working Directory            | Shows your current directory path.                                   

# File & Directory Manipulation
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **mkdir**  | Make Directory                     | Creates a new folder/directory.                                      |                                       |
| **rmdir**  | Remove Directory                   | Deletes an empty directory.                                          |                                       |
| **touch**  | Touch                              | Creates an empty file or updates its timestamp.                      |                                       |
| **rm**     | Remove                             | Deletes files or directories.                                        |                                       |
| **cp**     | Copy                               | Copies files or directories.                                         |                                       |
| **mv**     | Move                               | Moves or renames files/directories.                                  |                                       |
| **ln**     | Link                               | Creates hard or symbolic links between files.                        |                                       |

# Text Viewing & Editing
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **cat**    | Concatenate                        | Displays file content or concatenates files.                         |                                       |
| **head**   | Head                               | Shows the first few lines of a file.                                 |                                       |
| **tail**   | Tail                               | Shows the last few lines of a file.                                  |                                       |
| **nano**   | Nano Editor                        | A simple, user-friendly text editor.                                 |                                       |
| **vim**    | Vi IMproved                        | A powerful, advanced text editor.                                    |                                       |
| **less**   | Less                               | Interactively views file contents.                                   |                                       |
| **more**   | More                               | Views file contents page by page.                                    |                                       |

# Searching & Pattern Matching
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **grep**   | Global Regular Expression Print    | Searches text for patterns.                                          |                                       |
| **find**   | Find                               | Searches for files in a directory hierarchy.                         |                                       |
| **locate** | Locate                             | Quickly finds files by name using a prebuilt database.               |                                       |
| **awk**    | Awk                                | A powerful text-processing language for pattern scanning.            |                                       |
| **sed**    | Stream Editor                      | Filters and transforms text in a stream.                             |                                       |
| **diff**   | Difference                         | Compares files line by line.                                         |                                       |
| **sort**   | Sort                               | Sorts lines of text.                                                 |                                       |
| **uniq**   | Unique                             | Filters out repeated lines.                                          |                                       |
| **wc**     | Word Count                         | Counts lines, words, and characters in text.                         |                                       |

# Permissions & Ownership
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **chmod**  | Change Mode                        | Modifies file permissions.                                           |                                       |
| **chown**  | Change Owner                       | Changes the file's owner and group.                                  |                                       |

# Disk/Filesystem & Storage
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **df**     | Disk Free                          | Reports filesystem disk space usage.                                 |                                       |
| **du**     | Disk Usage                         | Estimates file/directory space usage.                                |                                       |
| **mount**  | Mount                              | Attaches a filesystem to a directory.                                |                                       |
| **umount** | Unmount                            | Detaches a mounted filesystem.                                       |                                       |
| **lsblk**  | List Block Devices                 | Displays block devices in a tree-like format.                        |                                       |
| **blkid**  | Block Identifier                   | Prints attributes of block devices.                                  |                                       |

# Process Management & Monitoring
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **ps**     | Process Status                     | Lists current active processes.                                      |                                       |
| **kill**   | Kill                               | Terminates a process by its PID.                                     |                                       |
| **top**    | Top                                | Provides real-time process monitoring.                               |                                       |
| **htop**   | Htop                               | An enhanced, interactive process monitor.                            |                                       |
| **free**   | Free                               | Displays system memory usage.                                        |                                       |
| **uptime** | Up Time                            | Shows how long the system has been running.                          |                                       |
| **dmesg**  | D Message                          | Prints kernel ring buffer messages.                                  |                                       |
| **systemctl** | System Control                  | Manages systemd services and system state.                           |                                       |
| **journalctl** | Journal Control                | Queries and displays systemd logs.                                   |                                       |

# System Information
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **uname**  | Unix Name                          | Displays kernel and system information.                              |                                       |
| **lscpu**  | List CPU                           | Shows CPU architecture information.                                  |                                       |
| **lsusb**  | List USB                           | Displays information about USB devices.                              |                                       |
| **lspci**  | List PCI                           | Lists all PCI devices.                                               |                                       |
| **dmidecode** | DMI Decode                      | Extracts hardware information from the BIOS.                         |                                       |

# Networking
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **ifconfig** | Interface Config                 | Displays/configures network interfaces (legacy tool).                |                                       |
| **ip**     | IP                                 | Manages network interfaces, routes, and tunnels.                     |                                       |
| **netstat**| Network Statistics                 | Displays network connections and routing tables.                     |                                       |
| **ss**     | Socket Statistics                  | Provides detailed socket information (faster than netstat).          |                                       |
| **ping**   | Ping                               | Tests connectivity by sending ICMP echo requests.                    |                                       |
| **traceroute** | Trace Route                    | Traces the network path to a remote host.                            |                                       |
| **wget**   | Web Get                            | Downloads files from the web non-interactively.                      |                                       |
| **curl**   | Client URL                         | Transfers data with URL syntax.                                      |                                       |
| **ssh**    | Secure Shell                       | Securely connects to remote systems via encryption.                  |                                       |
| **scp**    | Secure Copy                        | Securely copies files between hosts over SSH.                        |                                       |
| **rsync**  | Remote Sync                        | Efficiently synchronizes files/directories between locations.        |                                       |
| **dig**    | Domain Information Groper          | Performs DNS lookups.                                                |                                       |
| **host**   | Host                               | A simple DNS lookup utility.                                         |                                       |
| **whois**  | Who Is                             | Queries domain registration and WHOIS information.                   |                                       |

# Archiving & Compression
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **tar**    | Tape Archive                       | Combines multiple files into one archive.                            |                                       |
| **gzip**   | GNU Zip                            | Compresses files using the gzip algorithm.                           |                                       |
| **gunzip** | GNU Unzip                          | Decompresses files compressed with gzip.                             |                                       |
| **zip**    | Zip                                | Creates a ZIP archive of files.                                      |                                       |
| **unzip**  | Unzip                              | Extracts files from a ZIP archive.                                   |                                       |

# Shell Environment & History
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **echo**   | Echo                               | Outputs text or variables to the terminal.                           |                                       |
| **history**| History                            | Displays a list of previously executed commands.                     |                                       |
| **alias**  | Alias                              | Creates shortcuts or alternate names for commands.                   |                                       |
| **env**    | Environment                        | Displays environment variables.                                      |                                       |
| **export** | Export                             | Sets environment variables for child processes.                      |                                       |

# Security & Forensics
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **iptables** | IP Tables                        | Configures IPv4 firewall rules.                                      |                                       |
| **tcpdump**| TCP Dump                           | Captures and displays network packets.                               |                                       |
| **nmap**   | Network Mapper                     | Scans networks for hosts and services.                               |                                       |
| **strace** | System Trace                       | Traces system calls and signals of a process.                        |                                       |
| **lsof**   | List Open Files                    | Lists open files and the processes using them.                       |                                       |
| **nc**     | Netcat                             | Reads/writes data across network connections (“Swiss Army knife”).   |                                       |
| **socat**  | SOcket CAT                         | Relays bidirectional data between two endpoints.                     |                                       |

# Scheduling & Cron Job
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **cron**   | Cron                               | Daemon that executes scheduled tasks.                                |                                       |
| **crontab**| Cron Table                         | Edits or lists the table of scheduled jobs.                          |                                       |

# System Control
| Command    | Mnemonic/Meaning                   | Description                                                          |                                       |
|------------|------------------------------------|----------------------------------------------------------------------|---------------------------------------|
| **man**    | Manual                             | Displays the manual (documentation) for commands.                    |                                       |
| **date**   | Date                               | Displays or sets the system date and time.                           |                                       |
| **clear**  | Clear                              | Clears the terminal screen.                                          |                                       |
| **reboot** | Reboot                             | Restarts the system.                                                 |                                       |
| **shutdown**| Shutdown                          | Shuts down or restarts the system.                                   |                                       |
| **whoami** | Who Am I                           | Displays the current user.                                           |                                       |