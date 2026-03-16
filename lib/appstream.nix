{ lib, writeText }:

{ appId
, package
, appName ? null
, developer ? null
}:

let
  meta = package.meta or { };
  version = package.version or null;

  description = meta.description or null;
  longDescription = meta.longDescription or null;
  homepage = meta.homepage or null;

  # Build SPDX license expression (filter out licenses without spdxId)
  licensesToSpdx = l:
    let
      licenses = if builtins.isList l then l else [ l ];
      spdxIds = lib.filter (x: x != null) (map (x: x.spdxId or null) licenses);
    in
      if spdxIds == [] then null
      else lib.concatStringsSep " AND " spdxIds;
  spdxLicense = if meta ? license then licensesToSpdx meta.license else null;

  # Build description block: use longDescription for <p>, fall back to description
  descriptionBlock =
    if longDescription != null then
      "  <description>\n    <p>${lib.escapeXML (lib.removeSuffix "\n" longDescription)}</p>\n  </description>"
    else if description != null then
      "  <description>\n    <p>${lib.escapeXML description}</p>\n  </description>"
    else
      "";

  lines = [
    ''<?xml version="1.0" encoding="UTF-8"?>''
    ''<component type="desktop-application">''
    "  <id>${appId}</id>"
    "  <metadata_license>CC0-1.0</metadata_license>"
  ]
  ++ lib.optional (appName != null) "  <name>${lib.escapeXML appName}</name>"
  ++ lib.optional (description != null) "  <summary>${lib.escapeXML description}</summary>"
  ++ lib.optional (descriptionBlock != "") descriptionBlock
  ++ lib.optional (developer != null) "  <developer>\n    <name>${lib.escapeXML developer}</name>\n  </developer>"
  ++ lib.optional (homepage != null) "  <url type=\"homepage\">${lib.escapeXML homepage}</url>"
  ++ lib.optional (spdxLicense != null) "  <project_license>${lib.escapeXML spdxLicense}</project_license>"
  ++ lib.optional (version != null && version != "0") "  <releases>\n    <release version=\"${lib.escapeXML version}\" />\n  </releases>"
  ++ [
    "  <launchable type=\"desktop-id\">${appId}.desktop</launchable>"
    "</component>"
  ];

in writeText "appstream-${appId}.metainfo.xml" (
  lib.concatStringsSep "\n" lines + "\n"
)
