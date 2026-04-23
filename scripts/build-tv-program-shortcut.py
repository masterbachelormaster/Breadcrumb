#!/usr/bin/env python3
"""Generate the iOS-compatible Shortcut for German TV programme research."""

from __future__ import annotations

import plistlib
import uuid
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "shortcuts"
OUT_FILE = OUT_DIR / "TV Programm Deutschland.wflow"


def token_string(text: str, attachments: dict[str, dict[str, str]]) -> dict:
    return {
        "WFSerializationType": "WFTextTokenString",
        "Value": {
            "string": text,
            "attachmentsByRange": attachments,
        },
    }


def action_output(output_uuid: str, output_name: str) -> dict[str, str]:
    return {
        "Type": "ActionOutput",
        "OutputUUID": output_uuid,
        "OutputName": output_name,
    }


def current_date() -> dict[str, str]:
    return {
        "Type": "CurrentDate",
    }


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    date_list_uuid = str(uuid.uuid4()).upper()
    choose_day_uuid = str(uuid.uuid4()).upper()
    ask_time_uuid = str(uuid.uuid4()).upper()
    model_uuid = str(uuid.uuid4()).upper()

    date_list_prefix = "Aktuelles Datum und aktuelle Uhrzeit: "
    date_list_suffix = """

Erstelle genau 7 Listeneinträge für eine Auswahl im Kurzbefehl: heute und die folgenden sechs Tage.
Jeder Eintrag muss auf Deutsch im Format „Wochentag, den D. Monat“ stehen, zum Beispiel „Donnerstag, den 23. April“.
Nutze die Zeitzone Deutschland. Gib nur die sieben Listeneinträge zurück, keine Überschrift und keine Erklärung.
"""
    replacement = "\uFFFC"
    date_list_prompt = f"{date_list_prefix}{replacement}{date_list_suffix}"

    prompt_prefix = """Recherchiere das aktuelle Fernsehprogramm in Deutschland für diesen Zeitpunkt:

Tag: """
    prompt_middle = """
Uhrzeit: """
    prompt_suffix = """

Arbeite auf Deutsch. Verwende das ChatGPT-Modell mit aktueller Recherche, falls verfügbar. Bestimme zuerst die aktuell 10 meistgesehenen linearen TV-Sender in Deutschland anhand aktueller Marktanteils- oder Reichweitenquellen. Recherchiere danach für jeden dieser Sender das Programm zum ausgewählten Tag und zur ausgewählten Uhrzeit.

Gib das Ergebnis als kompakte Tabelle aus mit diesen Spalten:
Sender | Sendung | Start | Ende | Kurzbeschreibung | Quelle/Stand

Wichtig:
- Der ausgewählte Tag kommt aus einer dynamisch erzeugten 7-Tage-Liste: heute plus die folgenden sechs Tage.
- Nenne die Quellen oder den Stand der Recherche.
- Wenn ein Sender- oder Programmdatum unsicher ist, markiere es klar als unsicher.
- Erfinde keine Sendungen.
- Verwende die Zeitzone Deutschland.
"""
    prompt_text = f"{prompt_prefix}{replacement}{prompt_middle}{replacement}{prompt_suffix}"
    day_attachment_range = f"{{{len(prompt_prefix)}, 1}}"
    time_attachment_range = f"{{{len(prompt_prefix) + 1 + len(prompt_middle)}, 1}}"

    workflow = {
        "WFWorkflowActions": [
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.askllm",
                "WFWorkflowActionParameters": {
                    "UUID": date_list_uuid,
                    "WFGenerativeResultType": "List",
                    "WFLLMModel": "ChatGPT",
                    "WFLLMPrompt": token_string(
                        date_list_prompt,
                        {
                            f"{{{len(date_list_prefix)}, 1}}": current_date(),
                        },
                    ),
                },
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.choosefromlist",
                "WFWorkflowActionParameters": {
                    "UUID": choose_day_uuid,
                    "WFChooseFromListActionPrompt": "Wähle den Tag",
                    "WFChooseFromListActionSelectMultiple": False,
                    "WFChooseFromListActionSelectAll": False,
                    "WFInput": {
                        "WFSerializationType": "WFTextTokenAttachment",
                        "Value": action_output(
                            date_list_uuid,
                            "Response",
                        ),
                    },
                },
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.ask",
                "WFWorkflowActionParameters": {
                    "UUID": ask_time_uuid,
                    "WFAskActionPrompt": "Welche Uhrzeit?",
                    "WFInputType": "Time",
                    "WFAskActionDefaultAnswer": "20:15",
                    "DefaultAnswer": "20:15",
                    "timeAnswer": {
                        "hour": 20,
                        "minute": 15,
                    },
                },
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.askllm",
                "WFWorkflowActionParameters": {
                    "UUID": model_uuid,
                    "WFLLMModel": "ChatGPT",
                    "WFGenerativeResultType": "Automatic",
                    "WFLLMPrompt": token_string(
                        prompt_text,
                        {
                            day_attachment_range: action_output(
                                choose_day_uuid,
                                "Chosen Item",
                            ),
                            time_attachment_range: action_output(
                                ask_time_uuid,
                                "Ask for Input",
                            ),
                        },
                    ),
                },
            },
            {
                "WFWorkflowActionIdentifier": "is.workflow.actions.showresult",
                "WFWorkflowActionParameters": {
                    "Text": token_string(
                        replacement,
                        {
                            "{0, 1}": action_output(
                                model_uuid,
                                "Response",
                            )
                        },
                    )
                },
            },
        ],
        "WFWorkflowClientVersion": "9999",
        "WFWorkflowMinimumClientVersion": 900,
        "WFWorkflowMinimumClientVersionString": "900",
        "WFWorkflowHasOutputFallback": False,
        "WFWorkflowHasShortcutInputVariables": False,
        "WFWorkflowIcon": {
            "WFWorkflowIconGlyphNumber": 59726,
            "WFWorkflowIconStartColor": 2071128575,
        },
        "WFWorkflowImportQuestions": [],
        "WFQuickActionSurfaces": [],
        "WFWorkflowTypes": [],
        "WFWorkflowInputContentItemClasses": [
            "WFAppContentItem",
            "WFAppStoreAppContentItem",
            "WFArticleContentItem",
            "WFContactContentItem",
            "WFDateContentItem",
            "WFEmailAddressContentItem",
            "WFFolderContentItem",
            "WFGenericFileContentItem",
            "WFImageContentItem",
            "WFiTunesProductContentItem",
            "WFLocationContentItem",
            "WFDCMapsLinkContentItem",
            "WFAVAssetContentItem",
            "WFPDFContentItem",
            "WFPhoneNumberContentItem",
            "WFRichTextContentItem",
            "WFSafariWebPageContentItem",
            "WFStringContentItem",
            "WFURLContentItem",
        ],
        "WFWorkflowOutputContentItemClasses": [],
    }

    with OUT_FILE.open("wb") as file:
        plistlib.dump(workflow, file, fmt=plistlib.FMT_BINARY)

    print(OUT_FILE)


if __name__ == "__main__":
    main()
