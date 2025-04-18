import {
  Bytes,
  JSONValue,
  JSONValueKind,
  dataSource,
  json,
} from "@graphprotocol/graph-ts";
import { WorkflowMetadata } from "../generated/schema";

export function handleWorkflowMetadata(content: Bytes): void {
  let metadata = new WorkflowMetadata(dataSource.stringParam());
  const value = json.fromString(content.toString()).toObject();
  if (value) {
    let name = value.get("name");
    if (name && name.kind === JSONValueKind.STRING) {
      metadata.name = name.toString();
    }
    let tags = value.get("tags");
    if (tags && tags.kind === JSONValueKind.STRING) {
      metadata.tags = tags.toString();
    }

    let setup = value.get("setup");
    if (setup && setup.kind === JSONValueKind.STRING) {
      metadata.setup = setup.toString();
    }

    let description = value.get("description");
    if (description && description.kind === JSONValueKind.STRING) {
      metadata.description = description.toString();
    }

    let cover = value.get("cover");
    if (cover && cover.kind === JSONValueKind.STRING) {
      metadata.cover = cover.toString();
    }

    let workflow = value.get("workflow");
    if (workflow && workflow.kind === JSONValueKind.STRING) {
      metadata.workflow = workflow.toString();
    }

    let links = value.get("links");
    if (links && links.kind === JSONValueKind.ARRAY) {
      metadata.links = links
        .toArray()
        .filter((target: JSONValue) => target.kind === JSONValueKind.STRING)
        .map<string>((target: JSONValue) => target.toString());
    }

    metadata.save();
  }
}
