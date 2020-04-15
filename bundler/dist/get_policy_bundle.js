"use strict";
/**
 * Copyright 2020 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const common_1 = require("./common");
exports.ANNOTATION_NAME = "bundle";
exports.SINK_DIR = "sink_dir";
exports.OVERWRITE = "overwrite";
function getPolicyBundle(configs) {
    return __awaiter(this, void 0, void 0, function* () {
        // Get the paramters
        const annotationName = configs.getFunctionConfigValueOrThrow(exports.ANNOTATION_NAME);
        const sinkDir = configs.getFunctionConfigValue(exports.SINK_DIR);
        const overwrite = configs.getFunctionConfigValue(exports.OVERWRITE) === "true";
        // Build the policy library
        const library = new common_1.PolicyLibrary(configs.getAll());
        // Get bundle
        const bundle = library.bundles.get(annotationName);
        if (bundle === undefined) {
            throw new Error(`bundle does not exist: ` + annotationName + `.`);
        }
        // Write bundle to sink dir
        if (sinkDir) {
            bundle.write(sinkDir, overwrite);
        }
        // Return the bundle
        configs.deleteAll();
        configs.insert(...bundle.configs);
    });
}
exports.getPolicyBundle = getPolicyBundle;
getPolicyBundle.usage = `
Get policy bundle of constraints based on annoation.

Configured using a ConfigMap with the following keys:
${exports.ANNOTATION_NAME}: Name of the policy bundle.
${exports.OVERWRITE}: [Optional] If 'true', overwrite existing YAML files. Otherwise, fail if any YAML files exist.
${exports.SINK_DIR}: [Optional] Path to the config directory to write to; will create if it does not exist.
Example:
apiVersion: v1
kind: ConfigMap
data:
  ${exports.ANNOTATION_NAME}: 'bundles.validator.forsetisecurity.org/cis-v1.1'
  ${exports.OVERWRITE}: 'true'
  ${exports.SINK_DIR}: /path/to/sink/dir
metadata:
  name: my-config
`;
//# sourceMappingURL=get_policy_bundle.js.map