# server.py
from fastapi import FastAPI
from pydantic import BaseModel
import torch, numpy as np
from transformers import AutoTokenizer, AutoModelForTokenClassification
import os

app = FastAPI()
MODEL = "peterhung/vietnamese-accent-marker-xlm-roberta"
CACHE = os.path.expanduser("~/.cache/vn_accent")
TAG_FILE = os.path.join(CACHE, "selected_tags_names.txt")

# 1) Load tags
with open(TAG_FILE, encoding="utf-8") as f:
    labels = [l.strip() for l in f if l.strip()]

# 2) Load model & tokenizer once
tokenizer = AutoTokenizer.from_pretrained(MODEL, add_prefix_space=True)
model     = AutoModelForTokenClassification.from_pretrained(MODEL)
model.eval()

class TextIn(BaseModel):
    text: str

@app.post("/accent")
def accent(payload: TextIn):
    words  = payload.text.split()
    inputs = tokenizer(words,
                       is_split_into_words=True,
                       padding=True,
                       truncation=True,
                       return_tensors="pt")
    with torch.no_grad():
        logits = model(**inputs).logits.cpu().numpy()[0]
    preds  = np.argmax(logits, axis=1)[1:-1]
    toks   = tokenizer.convert_ids_to_tokens(inputs["input_ids"][0])[1:-1]

    out, i = [], 0
    while i < len(toks):
        if toks[i].startswith("▁"):
            w = toks[i][1:]; tags={preds[i]}; j=i+1
            while j < len(toks) and not toks[j].startswith("▁"):
                w+=toks[j]; tags.add(preds[j]); j+=1
            for t in tags:
                raw, acc = labels[t].split("-")
                if raw and raw in w:
                    w = w.replace(raw,acc)
                    break
            out.append(w); i=j
        else:
            out.append(toks[i]); i+=1

    return {"accented": " ".join(out)}
