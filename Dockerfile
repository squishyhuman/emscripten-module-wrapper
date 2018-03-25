FROM debian:stretch
MAINTAINER squishyhuman

# Install dependencies
RUN apt-get update && \
	apt-get install -y \
		`# Common packages` \
			git \
		`# OCalm off-chain interpreter packages` \
			wget \
			gcc \
			ocaml \
			opam \
			libzarith-ocaml-dev \
			m4 \
			pkg-config \
			zlib1g-dev

# Setup OPAM
RUN opam init -y && \
	eval `opam config env` && \
	opam install -y \
		cryptokit \
		yojson

# Setup OCaml off-chain interpreter
RUN git clone https://github.com/TrueBitFoundation/ocaml-offchain && \
	cd ocaml-offchain/interpreter && \
	eval `opam config env` && \
	make

# Setup Emscripten
RUN git clone https://github.com/juj/emsdk
RUN cd emsdk && \
	./emsdk install sdk-1.37.28-64bit && \
	./emsdk activate sdk-1.37.28-64bit
#RUN cd /root && \
#	sed -e "s/'\/emsdk\/clang\/e1.37.28_64bit'/'\/usr\/bin'/" .emscripten > emscripten && \
#	cp emscripten .emscripten && \
#	echo && \
#	echo && \
#	cat .emscripten && \
#	echo && \
#	echo


# Setup Node.js
#RUN curl -sL https://deb.nodesource.com/setup_9.x | bash - && \
#	apt-get install -y nodejs && \
#	npm install --unsafe-perm -g \
#		minimist \
#		ipfs-api


#COPY . /emscripten-module-wrapper
#WORKDIR emscripten-module-wrapper
#RUN rm -rf ocaml-offchain && \
#	ln -s ../ocaml-offchain ocaml-offchain
#WORKDIR ..

# Setup Emscripten module wrapper
RUN bash -c 'git clone https://github.com/TrueBitFoundation/emscripten-module-wrapper && \
	cd emscripten-module-wrapper && \
	source /emsdk/emsdk_env.sh && \
	npm install ipfs-api && \
	sed -e "s/\/home\/sami//" prepare.js > prepare2.js'

# Build example program
RUN git clone https://github.com/mrsmkl/coindrop
RUN bash -c 'cd coindrop && \
	source /emsdk/emsdk_env.sh && \
	emcc -o simple.js simple.c'

RUN bash -c 'cd coindrop && \
	`#emcc simple.c -s WASM=1 -o simple.js` && \
	touch output.data && \
	touch input.data && \
	node /emscripten-module-wrapper/prepare2.js simple.js --file input.data --file output.data'

#RUN git clone https://github.com/mrsmkl/coindrop.git

#WORKDIR coindrop

#	# Build example program
#	RUN /bin/bash -c "source ../emsdk-portable/emsdk_env.sh && \
#		emcc simple.c -s WASM=1 -o simple.js"
#
#	# Create empty files for input and output
#	RUN touch input.data && \
#		touch output.data
#
#	# Run example
#	RUN export NODE_PATH=$(npm root -g) &&  \
#		node ../emscripten-module-wrapper/prepare.js simple.js --file input.data --file output.data
#
#WORKDIR ..
