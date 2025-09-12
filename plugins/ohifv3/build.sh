#!/bin/bash
# Copyright (c) MONAI Consortium
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
curr_dir="$(pwd)"
my_dir="$(dirname "$(readlink -f "$0")")"
echo "Installing requirements..."
sh $my_dir/requirements.sh
install_dir=${1:-$my_dir/../../monailabel/endpoints/static/ohif}
echo "Current Dir: ${curr_dir}"
echo "My Dir: ${my_dir}"
echo "Installing OHIF at: ${install_dir}"
cd ${my_dir}
rm -rf Viewers
# Clone your fork repository
git clone https://github.com/prabin333/Viewers.git
cd Viewers
# Remove specific commit checkout since it may not exist in your fork
# git checkout d8ef36ed24466988586e19b855d2bbb86f8c657a
# Check if extensions directory exists, if not create it
if [ ! -d "extensions" ]; then
    mkdir -p extensions
fi
# Check if modes directory exists, if not create it  
if [ ! -d "modes" ]; then
    mkdir -p modes
fi
# Copy/link MONAILabel extensions
cd extensions
if [ -d "../../extensions/monai-label" ]; then
    ln -s ../../extensions/monai-label monai-label
else
    echo "Warning: ../../extensions/monai-label not found"
fi
cd ..
# Copy/link MONAILabel modes
cd modes
if [ -d "../../modes/monai-label" ]; then
    ln -s ../../modes/monai-label monai-label
else
    echo "Warning: ../../modes/monai-label not found"
fi
cd ..
# Apply patches if extensions.patch exists
if [ -f ../extensions.patch ]; then
    git apply ../extensions.patch
else
    echo "Warning: ../extensions.patch not found - skipping patch application"
fi
# Copy config if it exists
if [ -f ../config/monai_label.js ]; then
    mkdir -p platform/app/public/config/
    cp ../config/monai_label.js platform/app/public/config/monai_label.js
else
    echo "Warning: ../config/monai_label.js not found - skipping config copy"
fi
yarn config set workspaces-experimental true
yarn install
yarn run cli list
APP_CONFIG=config/monai_label.js PUBLIC_URL=/ohif/ QUICK_BUILD=true yarn run build
rm -rf ${install_dir}
cp -r platform/app/dist/ ${install_dir}
echo "Copied OHIF to ${install_dir}"
cd ..
rm -rf Viewers
find . -type d -name "node_modules" -exec rm -rf "{}" + 2>/dev/null || true
cd ${curr_dir}
