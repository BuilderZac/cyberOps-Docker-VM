# Use Kali Linux as the base image
FROM kalilinux/kali-rolling

# Update packages and install necessary tools
RUN apt-get update && \
    apt-get install -y \
    kali-linux-core \
    && rm -rf /var/lib/apt/lists/*

# Set the timezone to US Eastern Time
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Installing command-line forensics tools
RUN apt-get update && \
    apt-get install -y \
    neovim \
    lazygit \
    foremost \
    binwalk \
    steghide \
    hexedit \
    ghex \
    hashcat \ 
    john \
    exiftool \
    ffmpeg \
    nano \ 
    pngcheck \
    python2 \
    python2-dev \
    python3-dev \
    python3-bandit \
    python3-binwalk \
    python3-pip \
    python3-scapy \
    python3-pyx \
    python3-dogtail \
    python3-venv \
    python3-lxml \
    radare2 \
    sleuthkit \
    forensics-all \
    vim \
    tar \
    gzip \
    bzip2 \
    wget \
    curl \
    grep \
    gawk \
    tree \
    binwalk \
    foremost \
    binutils \
    scapy \
    traceroute \
    ca-certificates \
    jq \
    build-essential \
    pkg-config \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libffi-dev \
    libssl-dev \
    python3-lxml \
    dnsutils \
    whois \
    nmap \
    ripgrep \
    graphviz \
    metagoofil \
    subfinder \
    httpx-toolkit \
    amass \
    getallurls \
    recon-ng \
    theharvester \
    && rm -rf /var/lib/apt/lists/*

# Installing EmlAnalyzer - Email Forensics  & Volatility3 - Memory Forensics
#RUN pip3 install --upgrade pip eml-analyzer volatility3

# Installing Stegsolve, jsteg and slink - Stegnography
RUN cd /opt && \
    wget http://www.caesum.com/handbook/Stegsolve.jar -O stegsolve.jar && \
    chmod +x stegsolve.jar && \
    mkdir bin && \
    mv stegsolve.jar bin/

RUN wget -O /usr/local/bin/jsteg \
   https://github.com/lukechampine/jsteg/releases/download/v0.3.0/jsteg-linux-amd64 && \
   chmod +x /usr/local/bin/jsteg
RUN wget -O /usr/local/bin/slink \
   https://github.com/lukechampine/jsteg/releases/download/v0.3.0/slink-linux-amd64 && \
   chmod +x /usr/local/bin/slink

# Install nvim & load config
RUN mkdir /root/.config && \
    mkdir /root/.config/nvim && \
    git clone https://github.com/BuilderZac/nvim-config /root/.config/nvim/.

# Install omz with config
RUN RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
RUN cp /root/.oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc
RUN sed -i 's/^plugins=.*/plugins=(git sudo colorize command-not-found)/' /root/.zshrc \
 && sed -i 's/^ZSH_THEME=.*/ZSH_THEME="custom"/' /root/.zshrc

RUN cd ~/.oh-my-zsh/themes/ && wget https://raw.githubusercontent.com/BuilderZac/omz-custom/refs/heads/main/custom.zsh-theme

RUN set -eux; \
    sed -i 's/%n@%m"/%n@%m VM"/' "/root/.oh-my-zsh/themes/custom.zsh-theme"

# ------------------------------------------------------
# Python venv (PEP 668 safe)
# ------------------------------------------------------
ENV VENV=/opt/venv
RUN python3 -m venv $VENV
ENV PATH="$VENV/bin:/usr/local/bin:${PATH}"
RUN pip install --no-cache-dir -U pip setuptools wheel
ENV PIP_PREFER_BINARY=1

# ------------------------------------------------------
# SpiderFoot (GitHub) - skip lxml because apt provides it
# ------------------------------------------------------
RUN git clone --depth 1 https://github.com/smicallef/spiderfoot.git /opt/spiderfoot && \
    grep -vi '^\s*lxml' /opt/spiderfoot/requirements.txt > /tmp/sf_requirements.txt && \
    pip install --no-cache-dir -r /tmp/sf_requirements.txt

RUN printf '%s\n' '#!/usr/bin/env bash' \
  'exec python /opt/spiderfoot/sf.py "$@"' \
  > /usr/local/bin/spiderfoot && chmod +x /usr/local/bin/spiderfoot

# ------------------------------------------------------
# theHarvester (GitHub) - requires newer Python in recent versions
# Kali rolling typically satisfies this
# ------------------------------------------------------
#RUN git clone --depth 1 https://github.com/laramies/theHarvester.git /opt/theHarvester && \
#    cd /opt/theHarvester && \
#    pip install --no-cache-dir .

# ------------------------------------------------------
# OSINT Python tools + dnstwist + graph export libs
# ------------------------------------------------------
RUN pip install --no-cache-dir \
    sherlock-project \
    maigret \
    holehe \
    dnstwist \
    pandas \
    networkx \
    pyvis

# recon-ng
RUN git clone --depth 1 https://github.com/lanmaster53/recon-ng.git /opt/recon-ng

# ------------------------------------------------------
# Graph export helper
# ------------------------------------------------------
RUN cat > /usr/local/bin/osint-graph <<'PY' && chmod +x /usr/local/bin/osint-graph
#!/usr/bin/env python3
import sys
import networkx as nx
from pyvis.network import Network

def main():
    if len(sys.argv) < 2:
        print("Usage: osint-graph <edges.csv> [out_prefix]", file=sys.stderr)
        print("edges.csv: one edge per line: source,target", file=sys.stderr)
        sys.exit(2)

    edges_path = sys.argv[1]
    out_prefix = sys.argv[2] if len(sys.argv) > 2 else "graph"

    G = nx.DiGraph()
    with open(edges_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = [p.strip() for p in line.split(",")]
            if len(parts) >= 2:
                G.add_edge(parts[0], parts[1])

    dot_path = f"{out_prefix}.dot"
    html_path = f"{out_prefix}.html"

    with open(dot_path, "w", encoding="utf-8") as f:
        f.write("digraph G {\n")
        for u, v in G.edges():
            f.write(f'  "{u}" -> "{v}";\n')
        f.write("}\n")

    net = Network(height="750px", width="100%", directed=True)
    net.from_nx(G)
    net.show(html_path)

    print(f"Wrote: {dot_path}")
    print(f"Wrote: {html_path}")
    print("Optional render: dot -Tpng graph.dot -o graph.png")

if __name__ == "__main__":
    main()
PY

# ------------------------------------------------------
# Smoke tests
# ------------------------------------------------------
RUN python --version && \
    python -c "import lxml; print('lxml OK')" && \
    subfinder -version && \
    httpx -version && \
    amass version && \
    gau --help >/dev/null 2>&1 || true && \
    dnstwist --help >/dev/null 2>&1 || true && \
    metagoofil -h >/dev/null 2>&1 || true && \
    spiderfoot -h >/dev/null 2>&1 || true && \
    theHarvester -h >/dev/null 2>&1 || true

# Set the default command to run when the container starts
RUN touch ~/.hushlogin

# Remove the FALSE harvester
RUN rm /bin/theharvester

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

SHELL ["/usr/bin/zsh", "-c"]
CMD ["zsh", "-l"]
