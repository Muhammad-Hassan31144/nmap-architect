# 🛡️ Nmap Architect v2.0.0

**Advanced Interactive Nmap Command Builder for Professional Network Reconnaissance**

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/Muhammad-Hassan31144/nmap-architect)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-%3E%3D4.0-brightgreen.svg)](https://www.gnu.org/software/bash/)
[![Nmap](https://img.shields.io/badge/nmap-%3E%3D7.0-red.svg)](https://nmap.org/)

---

## 🚀 Overview

Nmap Architect is a sophisticated interactive tool that transforms complex Nmap command construction into an intuitive, menu-driven experience. Whether you're a security professional, penetration tester, or network administrator, this tool streamlines the process of building comprehensive network reconnaissance commands.

### 🎯 Key Features

- **🎨 Professional Interface**: Modern, emoji-enhanced menus with clear categorization
- **📋 Scan Templates**: 14+ pre-configured templates for common scenarios
- **🧪 NSE Script Engine**: Advanced script management and categorization
- **📊 Results Analysis**: Built-in scan result parsing and analysis
- **🛡️ Security Focus**: Ethical guidelines and best practices integration
- **⚡ Performance Optimized**: Smart defaults and validation

---

## 🆕 What's New in v2.0.0

### ✨ Major Enhancements

#### 🎯 **Scan Templates System**
Revolutionary pre-configured scan setups for instant deployment:

- **🔍 Discovery Templates**
  - Quick Host Discovery - Fast ping sweep and basic port check
  - Network Topology Scan - Comprehensive network mapping with traceroute
  - Stealth Reconnaissance - Low-profile information gathering

- **🔓 Penetration Testing Templates**
  - Fast Port Scan - Quick TCP port enumeration
  - Stealth Port Scan - Evade basic firewall detection
  - Comprehensive Scan - Deep analysis with version detection
  - Vulnerability Assessment - Security-focused scanning with vuln scripts

- **🌐 Service-Specific Templates**
  - Web Application Scan - HTTP/HTTPS service analysis
  - Mail Server Analysis - SMTP/POP3/IMAP enumeration
  - Remote Access Scan - SSH/RDP/VNC detection

- **🏢 Enterprise Templates**
  - Internal Network Audit - Comprehensive internal scanning
  - External Perimeter Scan - Public-facing service enumeration
  - Device Discovery Scan - Printers, IoT, embedded devices
  - Cloud Infrastructure - Cloud service enumeration

#### 🧪 **Advanced NSE Script Management**
Powerful Nmap Scripting Engine integration:

- **Categorized Script Selection**: Organized by purpose (vuln, discovery, auth, brute, etc.)
- **Custom Script Configuration**: Specify individual scripts and arguments
- **Safety Warnings**: Built-in alerts for potentially disruptive scripts
- **Script Search & Browse**: Find scripts by keyword or category
- **Argument Management**: Configure script-specific parameters

#### 📊 **Results Analysis System**
Built-in scan result processing and analysis:

- **Quick Summary**: Instant overview of scan results
- **Live Host Extraction**: Parse and list discovered hosts
- **Port Enumeration**: Summarize open ports by service
- **Service Analysis**: Extract service and version information
- **Statistics Overview**: Scan metrics and performance data
- **Multi-format Support**: Handle normal, XML, and grepable output

#### 💡 **Tips & Best Practices Integration**
Comprehensive knowledge base built into the tool:

- **Target Selection Guidelines**: Proper targeting and permission considerations
- **Performance Optimization**: Speed vs stealth trade-offs
- **Stealth Techniques**: Evasion strategies and timing considerations
- **Legal & Ethical Guidelines**: Responsible testing practices
- **Troubleshooting Guide**: Common issues and solutions

### 🎨 **Enhanced User Experience**

#### **Professional Interface Design**
- Modern ASCII art banner with Unicode styling
- Emoji-enhanced menus for visual clarity
- Logical grouping of related functions
- Professional branding and version information

#### **Improved Navigation**
- Quick-start templates for beginners
- Advanced options for experienced users
- Context-sensitive help throughout
- Breadcrumb navigation and clear exit paths

#### **Smart Validation**
- Real-time command validation
- Conflict detection between options
- Privilege requirement warnings
- Input sanitization and error handling

---

## 📋 Installation & Requirements

### Prerequisites
- **Bash**: Version 4.0 or higher
- **Nmap**: Version 7.0 or higher
- **Linux/Unix Environment**: Ubuntu, Debian, CentOS, macOS, WSL

### Quick Install
```bash
# Clone the repository
git clone https://github.com/Muhammad-Hassan31144/nmap-architect.git
cd nmap-architect

# Make executable
chmod +x nmap-architect.sh

# Run the tool
./nmap-architect.sh
```

### System Requirements
- Root privileges (for advanced scan types)
- Network connectivity
- Sufficient disk space for output files
- Permission to scan target systems

---

## 🎯 Quick Start Guide

### 1. Launch Nmap Architect
```bash
./nmap-architect.sh
```

### 2. Choose Your Approach

#### 🚀 **For Beginners**: Use Scan Templates
1. Select "📋 Scan Templates" from the main menu
2. Choose a template matching your objective
3. Configure target and execute

#### 🔧 **For Advanced Users**: Build Custom Scans
1. Start with "🎯 Target Specification"
2. Configure discovery, scan techniques, and options
3. Use "🧪 NSE Script Engine" for advanced analysis
4. Review and execute

### 3. Example Workflows

#### Quick Network Discovery
```bash
# Using template
1. Scan Templates → Quick Host Discovery
2. Enter target: 192.168.1.0/24
3. Execute

# Result: Fast ping sweep with DNS resolution
```

#### Comprehensive Security Assessment
```bash
# Using custom build
1. Target Specification → Enter: target.com
2. Scan Techniques → TCP SYN Scan
3. NSE Script Engine → Vulnerability Detection
4. Timing and Performance → T4
5. Execute

# Result: Full security assessment with vuln detection
```

---

## 📚 Menu Reference

### 🚀 **Quick Start**
| Option | Description | Use Case |
|--------|-------------|----------|
| 📋 Scan Templates | Pre-configured setups | Fast deployment |
| 🎯 Target Specification | Define scan targets | IP ranges, files, networks |

### 🔍 **Discovery & Scanning**
| Option | Description | Advanced Features |
|--------|-------------|-------------------|
| 📡 Host Discovery | Find live hosts | Multiple ping types, ARP scan |
| 🔓 Scan Techniques | Choose scan methods | SYN, Connect, UDP, stealth scans |
| 🔌 Port Specification | Configure ports | Ranges, top ports, custom lists |
| 🔬 Service Detection | Identify services | Version detection, intensity levels |
| 🖥️ OS Detection | Fingerprint systems | Aggressive vs passive detection |

### 🔬 **Advanced Analysis**
| Option | Description | Capabilities |
|--------|-------------|--------------|
| 🧪 NSE Script Engine | Advanced scripts | Vuln detection, service enum |
| ⏱️ Timing & Performance | Optimize scans | Speed vs stealth configuration |
| 🛡️ Firewall Evasion | Bypass security | Decoys, fragmentation, spoofing |

### ⚙️ **Configuration**
| Option | Description | Features |
|--------|-------------|----------|
| 🔧 Miscellaneous | Additional options | IPv6, privileges, data directories |
| 📄 Output Configuration | Results formatting | Multiple formats, verbosity |
| 📊 Results Analysis | Parse scan output | Summaries, statistics, extraction |

---

## 🛡️ Security & Ethics

### ⚠️ **Important Legal Notice**
This tool is designed for legitimate security testing and network administration. Users are responsible for:

- **Authorization**: Only scan systems you own or have explicit written permission to test
- **Compliance**: Follow all applicable local, state, and federal laws
- **Responsible Disclosure**: Report vulnerabilities through proper channels
- **Documentation**: Maintain proper testing documentation and scope

### 🎯 **Best Practices**
- Always verify target ownership before scanning
- Start with non-intrusive discovery scans
- Respect network resources and bandwidth
- Document your methodology for repeatability
- Keep tools and knowledge updated

---

## 🔧 Advanced Usage

### 🎛️ **Template Customization**
Templates can be modified after application:
```bash
1. Apply template: "Fast Port Scan"
2. Modify: Add NSE scripts via menu
3. Enhance: Configure custom timing
4. Execute: Run modified scan
```

### 🧪 **NSE Script Examples**
```bash
# Vulnerability Assessment
--script=vuln

# Web Application Testing
--script=http-*

# Database Enumeration
--script=mysql-*,ms-sql-*,oracle-*

# SSL/TLS Analysis
--script=ssl-*,tls-*
```

### 📊 **Output Processing**
```bash
# Save all formats
-oA scan_results

# XML for automated processing
-oX results.xml

# Grepable for parsing
-oG results.gnmap
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### 🐛 **Bug Reports**
- Use GitHub Issues
- Include OS and Nmap versions
- Provide steps to reproduce
- Include relevant command output

### ✨ **Feature Requests**
- Describe the use case
- Explain the expected behavior
- Consider backwards compatibility
- Provide implementation suggestions

### 🔧 **Development Setup**
```bash
git clone https://github.com/Muhammad-Hassan31144/nmap-architect.git
cd nmap-architect
# Make changes
./test_script.sh  # Run tests
git commit -m "Description"
git push origin feature-branch
```

---

## 📖 Resources

### 📚 **Documentation**
- [Official Nmap Documentation](https://nmap.org/docs.html)
- [NSE Script Reference](https://nmap.org/nsedoc/)
- [Nmap Scripting Engine](https://nmap.org/book/nse.html)

### 🎓 **Learning Resources**
- [Nmap Network Scanning Book](https://nmap.org/book/)
- [Security Testing with Nmap](https://nmap.org/docs.html)
- [Network Discovery Techniques](https://nmap.org/book/host-discovery.html)

### 🛠️ **Related Tools**
- [Masscan](https://github.com/robertdavidgraham/masscan) - Fast port scanner
- [Zmap](https://zmap.io/) - Internet-wide scanning
- [Nuclei](https://github.com/projectdiscovery/nuclei) - Vulnerability scanner

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Nmap Project**: For the incredible network discovery tool
- **Security Community**: For best practices and methodologies
- **Contributors**: Everyone who has helped improve this tool
- **Users**: For feedback and feature requests

---

## 📞 Support

### 🆘 **Getting Help**
- **Documentation**: Check this README and built-in help
- **GitHub Issues**: For bugs and feature requests
- **Discussions**: For general questions and tips
- **Wiki**: Community-contributed guides and tutorials

### 🏷️ **Version History**
- **v2.0.0** (2025-08-03): Major enhancement release
  - Scan templates system
  - NSE script management
  - Results analysis
  - Enhanced UI and help system
- **v1.x**: Original release with basic menu system

---

<div align="center">

**🛡️ Built with ❤️ for the Security Community 🛡️**

[⭐ Star this project](https://github.com/Muhammad-Hassan31144/nmap-architect) • [🐛 Report Bug](https://github.com/Muhammad-Hassan31144/nmap-architect/issues) • [✨ Request Feature](https://github.com/Muhammad-Hassan31144/nmap-architect/issues)

</div>
