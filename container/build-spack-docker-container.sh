#!/usr/bin/env bash

if [ $# -lt 1 ] || [ $# -gt 5 ]; then
    echo >&2
    echo "Usage: $(basename $0) (Spack_package_list_file) [APT_package_list_file] [extra_directories_file] [spack_directory] [lib_only=(1)|0]" >&2
    echo >&2
    echo "Example: c=nvhpc; $0 \${c}_spack.txt \${c}_apt.txt \${c}_extra.txt'" >&2
    echo >&2
    echo 'Build with: c=nvhpc; cp -a .dockerignore .dockerignore-$c; cp -a run.sh run-$c.sh; cp -a spack-libs.conf spack-libs-$c.conf; mv Dockerfile Dockerfile-$c; docke
r build --rm=true --tag=baip/compiler:$c-spack -f Dockerfile-$c .' >&2
    echo >&2
    exit -1;
fi

dockerfile=Dockerfile
dockerignore='.dockerignore'
entrypoint='run.sh'
spack_libs='spack-libs.conf'

spack_list_file="$1"

apt_list_file='NON_EXISTENT'
[ $# -ge 2 ] && apt_list_file="$2"

extra_directories_file='NON_EXISTENT'
[ $# -ge 3 ] && extra_directories_file="$3"

ROOT=$PWD
[ $# -ge 4 ] && ROOT="$4"
echo "Working directory: $ROOT"
echo

lib_only=1
[ $# -ge 5 ] && lib_only="$5"

printf "*\n!$spack_libs\n!$entrypoint\n" > $dockerignore

cat << EOF > $dockerfile
FROM ubuntu:20.04

WORKDIR $ROOT
EOF

# Create the entrypoint script to set up environment
cat << EOF > $entrypoint
#!/bin/bash

source /etc/profile
ulimit -s unlimited
EOF

if [ -e "$apt_list_file" ]; then
    # Install APT packages
    echo "!$apt_list_file" >> $dockerignore
    mapfile -t apt_packages < $apt_list_file
    cat << EOF >> $dockerfile

RUN apt-get -qy update && \\
    DEBIAN_FRONTEND="noninteractive" apt-get -qy install --no-install-recommends ${apt_packages[@]} && \\
    apt-get -qy clean
EOF
fi

if [ -e "$spack_list_file" ]; then
    # Install Spack packages
    echo "!$spack_list_file" >> $dockerignore
    mapfile -t spack_packages < $spack_list_file
    echo >> $dockerfile

    modules=()
    for pkg in "${spack_packages[@]}"; do
        if [ "$lib_only" -eq 0 ]; then
            # Copy installed directories
            d="$(spack find --format '{prefix}' $pkg)"
            r=${d#"$ROOT/"}
            echo "Installed location: $r"
            echo "COPY [\"$r\", \"$d\"]" >> $dockerfile
            echo "!$r" >> $dockerignore
        fi

        # Copy modulefiles
        d="$(spack module tcl find --full-path $pkg)"
        r=${d#"$ROOT/"}
        echo "Modulefile location: $r"
        echo "COPY [\"$r\", \"$d\"]" >> $dockerfile
        echo "!$r" >> $dockerignore

        # Collect module names
        modules+=("$(spack module tcl find $pkg)")
    done
    echo

    cat << EOF >> $entrypoint

module use --append $ROOT/share/spack/modules/linux-ubuntu20.04-haswell

module add ${modules[@]}
EOF
fi

if [ -e "$extra_directories_file" ]; then
    # Add extra library directories
    echo "!$extra_directories_file" >> $dockerignore
    mapfile -t extra_directories < $extra_directories_file
    extra_libraries="$(printf '%s:' ${extra_directories[@]})"
    printf "\nexport LD_LIBRARY_PATH=${extra_libraries}\${LD_LIBRARY_PATH:+\$LD_LIBRARY_PATH}\n" >> $entrypoint
fi

# Gather list of library directories
( unset LD_LIBRARY_PATH;
  source $entrypoint;
  IFS=':' read -ra lib_list <<< "$LD_LIBRARY_PATH";
  printf '%s\n' "${lib_list[@]}" > $spack_libs;
)

while IFS= read -r d; do
    r=${d#"$ROOT/"}
    echo "Library location: $r"
    target="$(readlink -f $d)"
    rel_target=${target#"$ROOT/"}
    if [ "$r" != "$rel_target" ]; then
        echo "Symbolic linked to: $rel_target"
        echo "RUN mkdir -p \"$(dirname $d)\" && ln -sf $target $d" >> $dockerfile
    fi
    if [ "$lib_only" -ne 0 ]; then
    # Copy library directories
        echo "COPY [\"$rel_target\", \"$target\"]" >> $dockerfile
    fi
    echo "!$rel_target" >> $dockerignore
done < $spack_libs

printf '\nexec "$@"\n' >> $entrypoint
chmod go=u-w $entrypoint
chmod a+x $entrypoint

# Copy the entrypoint script and call ldconfig
cat << EOF >> $dockerfile

COPY ["$spack_libs", "/etc/ld.so.conf.d/"]
RUN ldconfig

COPY ["$entrypoint", "$ROOT/"]
ENTRYPOINT ["$ROOT/$entrypoint"]
EOF

[ -e "$spack_list_file" ] && printf "\nCOPY [\"$spack_list_file\", \"$ROOT/\"]\n" >> $dockerfile
[ -e "$apt_list_file" ] && printf "\nCOPY [\"$apt_list_file\", \"$ROOT/\"]\n" >> $dockerfile
[ -e "$extra_directories_file" ] && printf "\nCOPY [\"$extra_directories_file\", \"$ROOT/\"]\n" >> $dockerfile
