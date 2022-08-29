#!/usr/bin/env python3

import yaml

from sys import argv


def find_images(spec, default_tag):
    images = []

    if repo := spec.get("repository"):
        tag = spec.get('tag') or default_tag
        image_name = f"{repo}:{tag}"
        
        if registry := spec.get("registry"):
            image_name = f"{registry}/{image_name}"

        images.append(image_name)

    for child in spec.values():
        if isinstance(child, dict):
            images.extend(find_images(child, default_tag))

    return images


def extract_images_from_yaml(file_name, default_tag):
    with open(file_name) as yaml_file:
        file_content = yaml.safe_load(yaml_file)
    return find_images(file_content, default_tag)


def main():
    try:
        _, file_name, default_tag = argv
    except:
        print(f"Usage: {argv[0]} <file name>")
    else:
        for image in extract_images_from_yaml(file_name, default_tag):
            print(image)

if __name__ == "__main__":
    main()

