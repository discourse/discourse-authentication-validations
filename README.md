# Discourse Authentication Validations

A Discourse plugin that adds advanced conditional logic and validation capabilities to user registration fields. This plugin allows you to create dynamic signup forms where field visibility and validation rules depend on user input, enabling complex registration workflows.

**Meta Topic**: https://meta.discourse.org/t/discourse-authentication-validations/292547

## Overview

This plugin extends Discourse's user field functionality by adding:

- **Conditional Field Display**: Show or hide fields based on the values of other fields
- **Field Chaining**: Create multi-level dependencies between fields
- **Custom Validation**: Apply regex-based validation to text fields
- **Dynamic Required Fields**: Automatically adjust required field status based on visibility

## Features

### 1. Conditional Field Visibility

Control when user fields appear during registration based on previous selections. For example:
- Show "Company Name" field only when user selects "Business" account type
- Display age verification fields only when user indicates they are under 18
- Show additional medical information fields based on initial health screening responses

### 2. Value-Based Triggers

Configure specific values that trigger field visibility:
- Single value triggers: Show field when parent equals specific value
- Multiple value triggers: Show field when parent matches any of several values
- Support for all field types: text, dropdown, checkbox/confirm

### 3. Nested Dependencies

Create multi-level conditional logic:
- Field A triggers Field B
- Field B triggers Field C
- When Field A changes, both Field B and Field C are automatically hidden and cleared

### 4. Regex Validation

Apply custom validation patterns to text fields:
- Email format validation
- Phone number patterns
- Custom ID formats
- Any regex-compatible validation rule

### 5. Smart Required Field Handling

The plugin intelligently manages required field validation:
- Hidden fields are automatically excluded from required validation
- Required status is preserved when fields become visible again
- Prevents validation errors for fields users cannot see

## Installation

1. Add the plugin to your Discourse instance:

```bash
cd /var/discourse
nano containers/app.yml
```

2. Add the repository under the `hooks.after_code` section:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/discourse/discourse-authentication-validations.git
```

3. Rebuild your container:

```bash
./launcher rebuild app
```

4. Enable the plugin in Admin Settings:
   - Navigate to Admin > Settings > Plugins
   - Enable "discourse authentication validations enabled"

## Configuration

### Setting Up Conditional Fields

1. **Navigate to User Fields**
   - Go to Admin > Customize > User Fields

2. **Create or Edit a Field**
   - Select the field that will control visibility of other fields

3. **Enable Custom Validation**
   - Check "Include a custom validation"

4. **Configure Trigger Values**
   - In "Show Values", enter the value(s) that will trigger display of target fields
   - Use multiple values to create OR logic (any value matches = show)

5. **Select Target Fields**
   - Choose which fields should appear when the trigger condition is met
   - You can select multiple target fields

6. **Optional: Add Regex Validation**
   - For text fields, add a regex pattern in "Value Validation Regex"
   - Pattern will be validated on form submission

### Example Configurations

#### Simple Conditional Display

**Use Case**: Show "Company Name" only for business accounts

- Parent Field: "Account Type" (dropdown with values: Personal, Business)
- Configuration:
  - Has Custom Validation: Yes
  - Show Values: `Business`
  - Target User Fields: "Company Name"

#### Multiple Trigger Values

**Use Case**: Show tax ID field for businesses and non-profits

- Parent Field: "Organization Type"
- Configuration:
  - Show Values: `Business`, `Non-Profit`, `Government`
  - Target User Fields: "Tax ID Number"

#### Nested Dependencies

**Use Case**: Medical screening workflow

- Field 1: "Do you have allergies?" (Yes/No)
  - Show Values: `Yes`
  - Target: "Allergy Type"

- Field 2: "Allergy Type" (Dropdown: Food, Medication, Environmental)
  - Show Values: `Food`
  - Target: "Specific Food Allergies"

#### Regex Validation

**Use Case**: Validate phone number format

- Field: "Phone Number"
- Configuration:
  - Has Custom Validation: Yes
  - Value Validation Regex: `^\+?[1-9]\d{1,14}$`
  - (Validates international phone format)

## Technical Details

### Database Schema

The plugin adds the following columns to the `user_fields` table:

- `has_custom_validation` (boolean): Enables conditional logic for this field
- `show_values` (text array): Values that trigger target field visibility
- `target_user_field_ids` (bigint array): IDs of fields to show when triggered
- `value_validation_regex` (string): Optional regex pattern for validation

### Client-Side Behavior

- Real-time field visibility toggling during registration
- Automatic clearing of hidden field values
- Preservation of original required status
- Nested validation handling (hiding child fields when parent is hidden)

### Server-Side Validation

- Required field validation skips hidden fields
- Regex validation applied during user creation
- Thread-safe field state management using ActiveSupport::CurrentAttributes

### Supported Field Types

- Text fields
- Dropdown/select fields
- Checkbox/confirm fields
- All standard Discourse user field types

## Requirements

- Discourse 2.7.0 or higher

## Support

For issues, questions, or feature requests:
- Meta Topic: https://meta.discourse.org/t/discourse-authentication-validations/292547

## License

See LICENSE file for details.
