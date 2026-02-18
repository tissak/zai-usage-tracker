#!/usr/bin/env python3
import json
import subprocess
import sys
import os
import shutil
import argparse

def get_json(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        print(f'Error decoding JSON from command: {cmd}')
        print(f'Output: {result.stdout}')
        return {}

def main():
    parser = argparse.ArgumentParser(description='Extract screenshot from xcresult')
    parser.add_argument('--path', required=True, help='Path to .xcresult bundle')
    parser.add_argument('--output', required=True, help='Output directory for screenshot')
    parser.add_argument('--name', default='PopoverScreenshot', help='Name prefix of the screenshot attachment')
    args = parser.parse_args()

    path = args.path
    screenshot_name = args.name
    output_dir = args.output

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print(f'🔍 Searching for screenshot "{screenshot_name}" in {path}...')

    # 1. Get list of tests to find the test ID
    cmd = ['xcrun', 'xcresulttool', 'get', 'test-results', 'tests', '--path', path, '--format', 'json']
    data = get_json(cmd)

    test_id = None

    def find_test_id(node):
        if node.get('name') == 'testTakeScreenshot()':
            return node.get('nodeIdentifier')
        
        for child in node.get('children', []):
            res = find_test_id(child)
            if res: return res
        return None

    for node in data.get('testNodes', []):
        test_id = find_test_id(node)
        if test_id: break

    if not test_id:
        print('❌ Could not find testTakeScreenshot() in results')
        sys.exit(1)

    print(f'✅ Found test ID: {test_id}')

    # 2. Export attachments for this test
    # We use a temporary directory for the export
    temp_dir = os.path.join(output_dir, 'temp_export')
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)

    print('📦 Exporting attachments...')
    cmd = ['xcrun', 'xcresulttool', 'export', 'attachments', '--path', path, '--test-id', test_id, '--output-path', temp_dir]
    subprocess.run(cmd, check=True)

    # 3. Find our specific screenshot in the exported files
    # The export command creates a manifest.json
    manifest_path = os.path.join(temp_dir, 'manifest.json')
    if not os.path.exists(manifest_path):
        print('❌ No manifest.json found in export')
        sys.exit(1)

    with open(manifest_path, 'r') as f:
        manifest = json.load(f)

    found = False
    # manifest is a list of test entries directly
    for test_entry in manifest:
        for attachment in test_entry.get('attachments', []):
            # Use suggestedHumanReadableName for matching, exportedFileName for the actual file
            name = attachment.get('suggestedHumanReadableName', '')
            if name.startswith(screenshot_name):
                filename = attachment.get('exportedFileName')
                source_path = os.path.join(temp_dir, filename)
                dest_path = os.path.join(output_dir, 'screenshot.png')
                shutil.move(source_path, dest_path)
                print(f'✨ Screenshot saved to {dest_path}')
                found = True
                break
        if found: break

    if not found:
        print(f'❌ Could not find attachment starting with {screenshot_name} in exported files')
        # List what was found
        print('Available attachments:')
        for test_entry in manifest:
            for attachment in test_entry.get('attachments', []):
                print(f"- {attachment.get('suggestedHumanReadableName')}")
        sys.exit(1)

    # Clean up temp dir
    shutil.rmtree(temp_dir)

if __name__ == '__main__':
    main()
