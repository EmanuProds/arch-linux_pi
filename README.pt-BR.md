# 🐧 Script de Pós-Instalação Arch Linux

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-3.0.0-blue.svg?style=for-the-badge)](https://github.com/EmanuProds/Post-Installation_Arch-Linux)

Um script moderno e interativo de automação de pós-instalação para sistemas Arch Linux com recursos abrangentes de configuração. 🚀

## ✨ Recursos

- **🖥️ Menus Interativos**: Interface amigável baseada em dialog para seleção de componentes
- **🏗️ Design Modular**: Código limpo e maintainable com funções separadas para cada componente
- **🛡️ Tratamento de Erros**: Validação abrangente e recuperação de erros
- **⚡ Práticas Modernas**: Usa melhores práticas do Bash com tratamento adequado de erros
- **🔧 Configuração Abrangente**: Cobre configuração do sistema, gráficos, ferramentas de desenvolvimento, aplicações, jogos e virtualização
- **🎮 Detecção Automática de GPU**: Detecta automaticamente e instala drivers apropriados de gráficos
- **💾 Sistema de Backup**: Cria backups de arquivos de configuração antes da modificação
- **📝 Logging**: Logging detalhado com saída colorida

## 🔧 Componentes

### ⚙️ Configuração do Sistema
- 🏪 Configuração do Pacman (multilib, cores, mirrors)
- 📦 Instalação do helper AUR (paru)
- 🌍 Configuração de locales do sistema
- 🔌 Serviços essenciais (Bluetooth, CUPS)

### 🎨 Gráficos e Exibição
- 🎮 Detecção automática de GPU e instalação de drivers
- 🎭 Configuração de temas e ícones (Adwaita, Papirus)
- 🖱️ Temas de cursor personalizados

### 💻 Ferramentas de Desenvolvimento
- 🐚 Personalização do terminal (Zsh, Oh My Bash)
- 🛠️ Pacotes de desenvolvimento (git, GitHub CLI)
- 💾 Linguagens de programação (Node.js, Python, Java)
- ⚡ Utilitários modernos de terminal (bat, exa, ripgrep, etc.)

### 📱 Aplicações
- 🔍 Utilitários do sistema (htop, fastfetch, etc.)
- 🎵 Codecs multimídia e players
- 📦 Aplicações Flatpak (Discord, Telegram, etc.)

### 🎮 Jogos
- 🕹️ Meta pacote de jogos
- 🍷 Configuração do Wine e Proton
- 🚂 Instalação do Steam

### 🖥️ Virtualização
- 🐧 Configuração do QEMU e virt-manager
- 🔒 Configuração do Libvirt

## 📋 Requisitos

- 🐧 Sistema Arch Linux
- 🌐 Conexão com internet
- 🔑 Privilégios sudo

## 🚀 Uso

### Modo Interativo (Recomendado)
```bash
./archPI
```

### Opções de Linha de Comando
```bash
./archPI --help     # 📖 Mostra mensagem de ajuda
./archPI --version  # 🔢 Mostra informação da versão
```

## 📦 Instalação

1. 📥 Clone ou baixe o repositório
2. ⚙️ Torne o script executável: `chmod +x archPI`
3. ▶️ Execute o script: `./archPI`
4. 📋 Siga os menus interativos para selecionar componentes

## 📁 Estrutura do Projeto

```
.
├── archPI                 # 🖥️ Script principal
├── assets/               # 🎨 Recursos de configuração
│   ├── .bash_aliases     # ⌨️ Aliases personalizados
│   ├── .bashrc          # 🐚 Configuração do Bash
│   └── cursor/          # 🖱️ Temas de cursor personalizados
├── README.md            # 📄 Este arquivo (Inglês)
├── README.pt-BR.md      # 📄 Versão em português
└── archPI-personal.sh   # 📜 Script pessoal legado (deprecated)
```

## 🛡️ Recursos de Segurança

- **💾 Criação de Backup**: Todos os arquivos de configuração modificados são backupados
- **🔍 Verificações de Dependências**: Verifica ferramentas necessárias antes da execução
- **🔄 Recuperação de Erros**: Tratamento graceful de falhas de instalação
- **✅ Confirmação do Usuário**: Solicita confirmação para operações importantes
- **🚫 Execução Não-Root**: Impede execução como root para operações de usuário

## 📄 Licença

Licença MIT - veja detalhes no repositório.
