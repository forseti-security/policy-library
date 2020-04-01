#
# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package templates.gcp.GCPFirewallRulesAllowlistConstraintV1

import data.validator.gcp.lib as lib

deny[{
	"msg": message,
	"details": metadata,
}] {
	constraint := input.constraint
	lib.get_constraint_params(constraint, params)

	asset := input.asset
	asset.asset_type == "compute.googleapis.com/Firewall"

	fw_rule = asset.resource.data

	violations := get_diff
	count(violations) > 0

	violation_msg := concat(" & ", violations)

	message := sprintf("%s Firewall rule is prohibited: %v", [asset.name, violation_msg])
	metadata := {
		"resource": asset.name,
		"restricted_rules": violations,
	}
}

###########################
# Rule Utilities
###########################

# Generate a violation if the firewall direction (ingress, egress, any) does not match
get_diff[output] {
	params := input.constraint.spec.parameters
	direction := lib.get_default(params.rules[_], "direction", "any")
	direction != "any"
	lower(direction) != lower(input.asset.resource.data.direction)
	output := "Firewall direction does not match"
}

# Generate a violation if the firewall rule_type (allowed, denied, any) does not match
get_diff[output] {
	params := input.constraint.spec.parameters
	rule_type := lib.get_default(params.rules[_], "rule_type", "any")
	rule_type != "any"
	not input.asset.resource.data[lower(rule_type)]
	output := "Firewall rule_type does not match"
}

# Generate a violation if the firewall protocol does not match
get_diff[output] {
	params := input.constraint.spec.parameters
	rule_type := lib.get_default(params.rules[_], "rule_type", "any")
	protocol := lib.get_default(params.rules[_], "protocol", "any")
	ip_configs := fw_rule_get_ip_configs(input.asset.resource.data, rule_type)

	protocol != "any"

	ip_configs[_].IPProtocol != protocol

	output := "Firewall protocol does not match"
}

# Generate a violation if the firewall protocol:port does not match
get_diff[output] {
	params := input.constraint.spec.parameters
	rule_type := lib.get_default(params.rules[_], "rule_type", "any")
	protocol := lib.get_default(params.rules[_], "protocol", "any")
	port := lib.get_default(params.rules[_], "port", "any")
	ip_configs := fw_rule_get_ip_configs(input.asset.resource.data, rule_type)

	protocol != "any"
	ip_configs[i].IPProtocol == protocol

	check_port_output := fw_rule_check_port(ip_configs[i], port)

	output := check_port_output
}

# Generate a violation if the firewall source range is passed and is not "*" and does not match or field does not exist
get_diff[output] {
	params := input.constraint.spec.parameters
	source_ranges := lib.get_default(params.rules[_], "source_ranges", ["any"])
	source_range := source_ranges[_]

	source_range != "any"
	source_range != "*"

	fw_rule_source_ranges = input.asset.resource.data.sourceRanges

	# check if any range matches exactly
	is_match := [match | check_exact_match(source_ranges[_], fw_rule_source_ranges); match = true]
	count(is_match) = 0

	output := "Firewall source range(s) does not match"
}

# Generate a violation if the firewall source range is passed and is not "*" and field does not exist
get_diff[output] {
	params := input.constraint.spec.parameters
	source_ranges := lib.get_default(params.rules[_], "source_ranges", ["any"])
	source_range := source_ranges[_]

	source_range != "any"
	source_range != "*"

	lib.has_field(input.asset.resource.data, "sourceRanges") == false

	output := "Firewall source ranges field does not exist"
}

# Generate a violation if the firewall source tag is passed and is not "*" and does not match
get_diff[output] {
	params := input.constraint.spec.parameters
	source_tags := lib.get_default(params.rules[_], "source_tags", ["any"])
	source_tag := source_tags[_]

	source_tag != "any"
	source_tag != "*"

	fw_rule_source_tags = input.asset.resource.data.sourceTags
	is_match := [match | check_re_match(source_tags[_], fw_rule_source_tags); match = true]
	count(is_match) = 0

	output := "Firewall source tag(s) does not match"
}

# Generate a violation if the firewall source tag is passed and is not "*" and field does not exist
get_diff[output] {
	params := input.constraint.spec.parameters
	source_tags := lib.get_default(params.rules[_], "source_tags", ["any"])
	source_tag := source_tags[_]

	source_tag != "any"
	source_tag != "*"

	lib.has_field(input.asset.resource.data, "sourceTags") == false

	output := "Firewall source tags field does not exist"
}

# Generate a violation if the firewall source service account is passed and is not "*" and does not match
get_diff[output] {
	params := input.constraint.spec.parameters
	source_service_accounts := lib.get_default(params.rules[_], "source_service_accounts", ["any"])
	source_service_account := source_service_accounts[_]

	source_service_account != "any"
	source_service_account != "*"

	fw_rule_source_sas = input.asset.resource.data.sourceServiceAccounts
	is_match := [match | check_re_match(source_service_accounts[_], fw_rule_source_sas); match = true]
	count(is_match) = 0

	output := "Firewall source service account(s) does not match"
}

# Generate a violation if the firewall source service account is passed and is not "*" and field does not exist
get_diff[output] {
	params := input.constraint.spec.parameters
	source_service_accounts := lib.get_default(params.rules[_], "source_service_accounts", ["any"])
	source_service_account := source_service_accounts[_]

	source_service_account != "any"
	source_service_account != "*"

	lib.has_field(input.asset.resource.data, "sourceServiceAccounts") == false

	output := "Firewall source service accounts field does not exist"
}

# Generate a violation if the firewall target range is passed and is not "*" and does not match or field does not exist
get_diff[output] {
	params := input.constraint.spec.parameters
	target_ranges := lib.get_default(params.rules[_], "target_ranges", ["any"])
	target_range := target_ranges[_]

	target_range != "any"
	target_range != "*"

	fw_rule_target_ranges = input.asset.resource.data.targetRanges

	# check if any range matches exactly
	is_match := [match | check_exact_match(target_ranges[_], fw_rule_target_ranges); match = true]
	count(is_match) = 0

	output := "Firewall target range(s) does not match"
}

# Generate a violation if the firewall target range is passed and is not "*" and field does not exist
get_diff[output] {
	params := input.constraint.spec.parameters
	target_ranges := lib.get_default(params.rules[_], "target_ranges", ["any"])
	target_range := target_ranges[_]

	target_range != "any"
	target_range != "*"

	lib.has_field(input.asset.resource.data, "targetRanges") == false

	output := "Firewall target ranges field does not exist"
}

# Generate a violation if the firewall target tag is passed and is not "*" and does not match
get_diff[output] {
	params := input.constraint.spec.parameters
	target_tags := lib.get_default(params.rules[_], "target_tags", ["any"])
	target_tag := target_tags[_]

	target_tag != "any"
	target_tag != "*"

	fw_rule_target_tags = input.asset.resource.data.targetTags
	is_match := [match | check_re_match(target_tags[_], fw_rule_target_tags); match = true]
	count(is_match) = 0

	output := "Firewall target tag(s) does not match"
}

# Generate a violation if the firewall target tag is passed and is not "*" and field does not exist
get_diff[output] {
	params := input.constraint.spec.parameters
	target_tags := lib.get_default(params.rules[_], "target_tags", ["any"])
	target_tag := target_tags[_]

	target_tag != "any"
	target_tag != "*"

	lib.has_field(input.asset.resource.data, "targetTags") == false

	output := "Firewall target tags field does not exist"
}

# Generate a violation if the firewall target service account is passed and is not "*" and does not match
get_diff[output] {
	params := input.constraint.spec.parameters
	target_service_accounts := lib.get_default(params.rules[_], "target_service_accounts", ["any"])
	target_service_account := target_service_accounts[_]

	target_service_account != "any"
	target_service_account != "*"

	fw_rule_target_sas = input.asset.resource.data.targetServiceAccounts
	is_match := [match | check_re_match(target_service_accounts[_], fw_rule_target_sas); match = true]
	count(is_match) = 0

	output := "Firewall target service account(s) does not match"
}

# Generate a violation if the firewall target service account is passed and is not "*" and field does not exist
get_diff[output] {
	params := input.constraint.spec.parameters
	target_service_accounts := lib.get_default(params.rules[_], "target_service_accounts", ["any"])
	target_service_account := target_service_accounts[_]

	target_service_account != "any"
	target_service_account != "*"

	lib.has_field(input.asset.resource.data, "targetServiceAccounts") == false

	output := "Firewall target service accounts field does not exist"
}

# Generate a violation if the firewall enabled field is not set to any and does not match disabled
get_diff[output] {
	params := input.constraint.spec.parameters
	enabled := lib.get_default(params.rules[_], "enabled", "any")

	enabled != "any"

	# the following test only works when enabled is a boolean too
	is_boolean(enabled)
	enabled == input.asset.resource.data.disabled
	output := "Firewall enabled field does not match"
}

# Generate a violation if the firewall enabled field is set to "true" (string) and does not match disabled
# This function is just for convenience when the enabled parameter is a string instead of a boolean
get_diff[output] {
	params := input.constraint.spec.parameters
	enabled := lib.get_default(params.rules[_], "enabled", "any")

	enabled != "any"

	# this is necessary as cast_boolean does not work on strings...
	is_string(enabled)
	lower(enabled) == "true"
	input.asset.resource.data.disabled
	output := "Firewall enabled field does not match"
}

# Generate a violation if the firewall enabled field is set to "false" (string) and does not match disabled
# This function is just for convenience when the enabled parameter is a string instead of a boolean
get_diff[output] {
	params := input.constraint.spec.parameters
	enabled := lib.get_default(params.rules[_], "enabled", "any")

	enabled != "any"

	# this is necessary as cast_boolean does not work on strings...
	is_string(enabled)
	lower(enabled) == "false"
	not input.asset.resource.data.disabled
	output := "Firewall enabled field does not match"
}

###########################
# Helper Functions
###########################

##### Get IP Config from rule

### fw_rule_get_ip_configs when rule_type is set to any and rule is allowed type
fw_rule_get_ip_configs(fw_rule, rule_type) = ip_configs {
	rule_type == "any"
	ip_configs = fw_rule.allowed
}

### fw_rule_get_ip_configs when rule_type is set to any and rule is allowed type
fw_rule_get_ip_configs(fw_rule, rule_type) = ip_configs {
	rule_type == "any"
	ip_configs = fw_rule.denied
}

### fw_rule_get_ip_configs when rule_type is not set to any
fw_rule_get_ip_configs(fw_rule, rule_type) = ip_configs {
	rule_type != "any"
	ip_configs = fw_rule[rule_type]
}

# port_is_not_in_values if rule_port is not a range
# Note: only called when port is not a range
port_is_not_in_values(port, rule_port) {
	# check if rule_port is not a range
	not re_match("-", rule_port)

	# test if rule port matches
	rule_port != port
}

# port_is_not_in_values if rule_port is a range
# Note: only called when port is not a range
port_is_not_in_values(port, rule_port) {
	# check if rule_port is a range
	re_match("-", rule_port)

	# build a simple port-port range to test if it belongs to rule_port range
	port_range := sprintf("%s-%s", [port, port])

	# Check if port is included in rule port
	not range_match(port_range, rule_port)
}

# range_match tests if test_range is included in target_range
# returns true if test_range is equal to, or included in target_range
range_match(test_range, target_range) {
	# check if target_range is a range
	re_match("-", target_range)

	# check if test_range is a range
	re_match("-", test_range)

	# getting the target range bounds
	target_range_bounds := split(target_range, "-")
	target_low_bound := to_number(target_range_bounds[0])
	target_high_bound := to_number(target_range_bounds[1])

	# getting the test range bounds
	test_range_bounds := split(test_range, "-")
	test_low_bound := to_number(test_range_bounds[0])
	test_high_bound := to_number(test_range_bounds[1])

	# check if test low bound is >= target low bound and target high bound >= test high bound
	test_low_bound >= target_low_bound

	test_high_bound <= target_high_bound
}

# re_match param with fw_rule asset
check_re_match(param, fw_rule) {
	re_match(param, fw_rule[_])
}

check_re_match(param, fw_rule) = false {
	re_match(param, fw_rule[_]) == false
}

check_exact_match(param, fw_rule) {
	param == fw_rule[_]
}

check_exact_match(param, fw_rule) = false {
	param != fw_rule[_]
}

# Generate a violation if the firewall port does not match when port is a single number
fw_rule_check_port(ip_config, port) = output {
	port != "any"
	not re_match("-", port)

	# check if the ports field exists
	lib.has_field(ip_config, "ports") == true

	# check if the port matches
	rule_ports := ip_config.ports

	# check if port is in one of rule_ports values
	port_is_not_in_values(port, rule_ports[_])

	output := "Firewall ports does not match"
}

# Generate a violation if the firewall ports field does not exist when port is a single number
fw_rule_check_port(ip_config, port) = output {
	port != "any"
	not re_match("-", port)

	# check if the ports field exists
	lib.has_field(ip_config, "ports") == false

	output := "Firewall ports field does not exist"
}

# Generate a violation if the firewall port does not match when port is a range (e.g 100-200)
fw_rule_check_port(ip_config, port) = output {
	port != "any"
	re_match("-", port)

	# check if the port range is included in the fw_rule port
	rule_ports := ip_config.ports

	rule_port := rule_ports[_]

	# check if port range is included in one of rule_ports values
	# Note: if rule_port is not a range, range_match will return False
	not range_match(port, rule_port)

	output := "Firewall port range(s) does not match"
}

# Generate a violation if the firewall ports field does not exist when port is a range (e.g 100-200)
fw_rule_check_port(ip_config, port) = output {
	port != "any"
	re_match("-", port)

	# check if the ports field exists
	lib.has_field(ip_config, "ports") == false

	output := "Firewall ports field does not exist"
}

# Generate a violation if the source ranges field does not exist
fw_rule_check_source_range(fw_rule, source_range) = output {
	lib.has_field(fw_rule, "sourceRanges") == false

	output := "Firewall source ranges field does not exist"
}

# Generate a violation if the source ranges does not match
fw_rule_check_source_range(fw_rule, source_range) = output {
	fw_rule_ranges := fw_rule.sourceRanges

	# check if any range matches
	# no CIDR matching logic at this time
	source_range != fw_rule_ranges[_]

	output := "Firewall source range(s) does not match"
}
