FROM debian:stretch
MAINTAINER squishyhuman

# Install dependencies
RUN apt-get update && \
	apt-get install -y \
		`# Common packages` \
			git \
			curl \
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

# Setup Emscripten
RUN curl https://s3.amazonaws.com/mozilla-games/emscripten/releases/emsdk-portable.tar.gz > emsdk-portable.tar.gz && \
    tar xzf emsdk-portable.tar.gz && \
    rm emsdk-portable.tar.gz && \
    cd emsdk-portable && \
    ./emsdk update && \
    ./emsdk install latest && \
    ./emsdk activate latest

# Setup Node.js
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash - && \
	apt-get install -y nodejs && \
	npm install --unsafe-perm -g \
		minimist \
		ipfs-api

# Clone empscripten wrapper
RUN git clone https://github.com/squishyhuman/emscripten-module-wrapper.git -b fix-paths

WORKDIR emscripten-module-wrapper

	# Clone OCaml off-chain interpreter
	RUN git submodule init && \
		git submodule update

	WORKDIR ocaml-offchain
		WORKDIR interpreter

			# Build OCaml off-chain interpreter
			RUN eval `opam config env` && \
				make

		WORKDIR ..
	WORKDIR ..
WORKDIR ..

# Clone example program
RUN git clone https://github.com/mrsmkl/coindrop.git

WORKDIR coindrop

	# Build example program
	RUN /bin/bash -c "source ../emsdk-portable/emsdk_env.sh && \
		emcc simple.c -s WASM=1 -o simple.js"

	# Create empty files for input and output
	RUN touch input.data && \
		touch output.data

	# Run example
	RUN export NODE_PATH=$(npm root -g) &&  \
		nodejs ../emscripten-module-wrapper/prepare.js simple.js --file input.data --file output.data

WORKDIR ..
