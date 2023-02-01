#!/usr/bin/env bash

cd "$1"/"$2"
# install or update pip and yq if they are not installed or up to date
for pkg in pydoc-markdown; do
  pip3 list --q --q --uptodate | grep "${pkg} " || pip3 install --upgrade ${pkg} --q --q
done

pydoc-markdown -m "$3"."$4" -I $(pwd) -q '{
    renderer: {
      type: markdown,
      descriptive_class_title: true,
      descriptive_module_title: true,
      add_module_prefix: true,
      add_member_class_prefix: true,
      insert_header_anchors: false,
      code_headers: true,
      format_code: false,
      signature_in_header: false,
      use_fixed_header_levels: true,
      header_level_by_type:{
        Module: 4,
        Class: 4,
        Function: 4,
        Method: 4,
        Data: 4
      }
    }
  }' > "$1"/"$2"/"$5"/"$4".md

