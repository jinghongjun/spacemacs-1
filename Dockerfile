FROM debian:latest

MAINTAINER JAremko <w3techplaygound@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# Basic stuff

COPY cleanup.sh /usr/local/bin/cleanup.sh
COPY aptupd.sh /usr/local/bin/aptupd.sh

RUN echo "deb http://http.debian.net/debian jessie-backports main contrib non-free" \
      >> /etc/apt/sources.list.d/sources.list                                                     
      
RUN sh /usr/local/bin/aptupd.sh                          && \
    apt-get install -y tar sudo bash fontconfig curl git    \
      htop unzip openssl mosh rsync make                 && \
    sh /usr/local/bin/cleanup.sh 

# Setup user

ENV uid 1000
ENV gid 1000
ENV UNAME jare

RUN mkdir -p /home/${UNAME}/workspace                                                   && \
    echo "${UNAME}:x:${uid}:${gid}:${UNAME},,,:/home/${UNAME}:/bin/bash" >> /etc/passwd && \
    echo "${UNAME}:x:${uid}:" >> /etc/group                                             && \
    echo "${UNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${UNAME}                   && \
    echo "docker:x:999:${UNAME}" >> /etc/group                                          && \
    chmod 0440 /etc/sudoers.d/${UNAME}                                                  && \
    chown ${uid}:${gid} -R /home/${UNAME}

USER ${UNAME}

RUN mkdir -p $HOME/.ssh   && \
    chmod 664 $HOME/.ssh 
    
ENV HOME /home/${UNAME}

LABEL HOME=$HOME

ENV GOPATH $HOME/workspace
ENV GOROOT /usr/lib/go
ENV GOBIN $GOROOT/bin

ENV NODEBIN /usr/lib/node_modules/bin

ENV PATH $PATH:$GOBIN:$GOPATH/bin:$NODEBIN

# Bash

RUN echo "export HOME=$HOME" >> $HOME/.bashrc                             && \
    echo "export GOPATH=$GOPATH" >> $HOME/.bashrc                         && \
    echo "export GOROOT=$GOROOT" >> $HOME/.bashrc                         && \
    echo "export GOBIN=$GOBIN" >> $HOME/.bashrc                           && \
    echo "export NODEBIN=$NODEBIN" >> $HOME/.bashrc                       && \
    echo "export PATH=$PATH:$GOBIN:$GOPATH/bin:$NODEBIN" >> $HOME/.bashrc && \
    . $HOME/.bashrc                                                     

# Fonts

ADD https://github.com/adobe-fonts/source-code-pro/archive/2.010R-ro/1.030R-it.zip /tmp/scp.zip
ADD http://www.ffonts.net/NanumGothic.font.zip /tmp/ng.zip

RUN sudo mkdir -p /usr/local/share/fonts               && \
    sudo unzip /tmp/scp.zip -d /usr/local/share/fonts  && \
    sudo unzip /tmp/ng.zip -d /usr/local/share/fonts   && \
    sudo chown ${uid}:${gid} -R /usr/local/share/fonts && \
    sudo chmod 777 -R /usr/local/share/fonts           && \
    sudo fc-cache -fv                                  && \
    sudo sh /usr/local/bin/cleanup.sh 

# Fish

RUN sudo sh /usr/local/bin/aptupd.sh                                                       && \
    sudo apt-get -y install fish                                                           && \

    sudo sed -i 's/\/bin\/ash/\/usr\/bin\/fish/g' /etc/passwd                              && \

    mkdir -p $HOME/.config/fish                                                            && \

    echo "set -x HOME $HOME" >> $HOME/.config/fish/config.fish                             && \
    echo "set -x GOPATH $GOPATH" >> $HOME/.config/fish/config.fish                         && \
    echo "set -x GOROOT $GOROOT" >> $HOME/.config/fish/config.fish                         && \
    echo "set -x GOBIN $GOBIN" >> $HOME/.config/fish/config.fish                           && \
    echo "set -x NODEBIN $NODEBIN" >> $HOME/.config/fish/config.fish                       && \
    echo "set -g fish_key_bindings fish_vi_key_bindings" >> $HOME/.config/fish/config.fish && \
    echo "set --universal fish_user_paths $fish_user_paths $GOBIN $GOPATH/bin $NODEBIN"       \
      >> $HOME/.config/fish/config.fish                                                    && \

    fish -c source $HOME/.config/fish/config.fish                                          && \
    
    sudo sh /usr/local/bin/cleanup.sh

# Iceweasel

RUN sudo sh /usr/local/bin/aptupd.sh                                  && \
    sudo apt-get install -y iceweasel libgl1-mesa-dri libgl1-mesa-glx && \
    sudo sh /usr/local/bin/cleanup.sh

# Emacs

RUN sudo sh /usr/local/bin/aptupd.sh                               && \
    sudo apt-get install -y emacs ispell iamerican-insane dbus-x11    \
      libegl1-mesa                                                 && \

    sudo sh /usr/local/bin/cleanup.sh

# Spacemacs

COPY .spacemacs $HOME/.spacemacs
                   
RUN git clone https://github.com/AndreaCrotti/yasnippet-snippets.git     \
      /tmp/snippets                                                   && \

git clone https://github.com/JAremko/spacemacs-pr.git -b doc-fmt         \
      $HOME/.emacs.d                                                  && \
   
    sudo mv -f /tmp/snippets $HOME/.emacs.d/private/snippets          && \
      
    sudo find $HOME/                                                     \
      \( -type d -exec chmod u+rwx,g+rwx,o+rx {} \;                      \
      -o -type f -exec chmod u+rw,g+rw,o+r {} \; \)                   && \
     
    sudo chown -R ${uid}:${gid} $HOME                                 && \    
    export SHELL=/usr/bin/fish                                        && \

    emacs -nw -batch -u "${UNAME}" -q -kill                           && \
    emacs -nw -batch -u "${UNAME}" -q -kill                           && \

    sudo sh /usr/local/bin/cleanup.sh

ENV GOPATH $HOME/workspace
    
# Node.js

USER root

RUN sh /usr/local/bin/aptupd.sh                            && \
    curl -sL https://deb.nodesource.com/setup_5.x | bash - && \
    apt-get install -y nodejs                              && \
    sh /usr/local/bin/cleanup.sh                        

USER ${UNAME}

# TypeScript stuff

RUN sudo npm install -g bower typescript typings tslint tsun        \
      yo generator-polymer polymer-ts-gen karma jasmine             \
      protractor webpack webpack-dev-server typescript-formatter && \
     
    sudo sh /usr/local/bin/cleanup.sh
    
# Compass

RUN sudo sh /usr/local/bin/aptupd.sh     && \
    sudo apt-get install -y ruby-compass && \
    sudo sh /usr/local/bin/cleanup.sh
    
# Slim

RUN sudo gem install slim slim_lint && \
    sudo sh /usr/local/bin/cleanup.sh

# PhantomJS

RUN sudo sh /usr/local/bin/aptupd.sh                                                  && \
    sudo apt-get install -y wget bzip2                                                && \

    PHANTOM_JS=phantomjs-2.1.1-linux-x86_64                                           && \
    cd /tmp/                                                                          && \
    wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2          && \
    sudo mv $PHANTOM_JS.tar.bz2 /usr/local/share/                                     && \
    cd /usr/local/share/                                                              && \
    sudo tar xvjf $PHANTOM_JS.tar.bz2                                                 && \
    sudo ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/share/phantomjs && \
    sudo ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin/phantomjs   && \
    sudo ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/bin/phantomjs         && \
    sudo rm -fr $PHANTOM_JS.tar.bz2                                                   && \

    sudo apt-get -y purge wget bzip2                                                  && \
    sudo sh /usr/local/bin/cleanup.sh
    
# Golang

RUN sudo sh /usr/local/bin/aptupd.sh                                   && \
    sudo apt-get install -y mercurial golang-go                        && \

    sudo chown ${uid}:${gid} -R $GOROOT                                && \
    sudo chown ${uid}:${gid} -R /usr/share/go                          && \
    sudo chown ${uid}:${gid} -R $GOPATH                                && \
    
    go get -u -buildmode=exe -ldflags '-s -w'                             \
    
      golang.org/x/tools/cmd/benchcmp                                     \
      golang.org/x/tools/cmd/bundle                                       \
      golang.org/x/tools/cmd/callgraph                                    \
      golang.org/x/tools/cmd/cover                                        \
      golang.org/x/tools/cmd/digraph                                      \
      golang.org/x/tools/cmd/eg                                           \
      golang.org/x/tools/cmd/fiximports                                   \
      golang.org/x/tools/cmd/godex                                        \
      golang.org/x/tools/cmd/godoc                                        \
      golang.org/x/tools/cmd/goimports                                    \
      golang.org/x/tools/cmd/gomvpkg                                      \
      golang.org/x/tools/cmd/gorename                                     \
      golang.org/x/tools/cmd/gotype                                       \
      golang.org/x/tools/cmd/html2article                                 \
      golang.org/x/tools/cmd/oracle                                       \
      golang.org/x/tools/cmd/present                                      \
      golang.org/x/tools/cmd/ssadump                                      \
      golang.org/x/tools/cmd/stress                                       \
      golang.org/x/tools/cmd/stringer                                     \
      golang.org/x/tools/cmd/tip                                          \
      golang.org/x/tools/cmd/vet                                          \
      golang.org/x/tools/refactor/eg                                      \
      golang.org/x/tools/refactor/importgraph                             \
      golang.org/x/tools/refactor/rename                                  \
      golang.org/x/tools/refactor/satisfy                                 \

      github.com/rogpeppe/godef                                           \
      github.com/tools/godep                                              \
      github.com/nsf/gocode                                               \
      github.com/kisielk/errcheck                                         \
      github.com/golang/lint/golint                                       \
      github.com/jstemmer/gotags                                          \
      github.com/dougm/goflymake                                          \
      github.com/golang/mock/mockgen                                      \
      github.com/alecthomas/gometalinter                               && \

    gometalinter --install --update                                    && \
    
    rm -rf $GOPATH/*                                                   && \
    
#    export GOPATH=/usr/share/go                                        && \
#    
#    go get -u                                                             \
#      github.com/golang/mock/gomock                                       \
#      github.com/onsi/ginkgo/ginkgo                                       \
#      github.com/onsi/gomega                                              \
#     github.com/sclevine/agouti                                           \
#
#      github.com/GeertJohan/go.rice                                       \
#      github.com/GeertJohan/go.rice/rice                                  \
#      
#      gopkg.in/godo.v2/cmd/godo                                           \
#      github.com/fatih/color                                           && \
      
    sudo chown ${uid}:${gid} -R $GOROOT                                && \
    sudo chown ${uid}:${gid} -R $GOPATH                                && \

    sudo sh /usr/local/bin/cleanup.sh

EXPOSE 80 8080 443 3000

COPY start.bash /usr/local/bin/start.bash

ENTRYPOINT ["bash", "/usr/local/bin/start.bash"]
