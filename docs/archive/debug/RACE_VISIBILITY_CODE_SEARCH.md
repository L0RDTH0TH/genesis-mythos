# RACE NODE VISIBILITY CODE SEARCH - COMPLETE RESULTS

## Search Criteria
Searching for code that:
1. Calls `.hide()` on race-related nodes
2. Sets `.visible = false` on race-related nodes
3. Sets `.modulate = Color(1,1,1,0)` or similar transparency
4. Calls `queue_free()` on race nodes

---

## 1. `.hide()` CALLS

### Search Pattern: `\.hide\(\)`

**Result:** ✅ **NO MATCHES FOUND**

**Conclusion:** No `.hide()` calls exist anywhere in the codebase.

---

## 2. `.visible = false` ASSIGNMENTS

### Search Pattern: `\.visible\s*=\s*false`

**Result:** ✅ **NO MATCHES FOUND**

**Conclusion:** No explicit `visible = false` assignments found in the codebase.

---

## 3. MODULATE WITH ALPHA = 0

### Search Pattern: `\.modulate\s*=.*Color.*0\)|modulate.*alpha.*0`

**Result:** Only found in documentation/reports, NOT in actual code

**Files Found:**
- `TAB_CONTAINER_VISIBILITY_REPORT.md` - Only mentions it as a check, no actual code

**Conclusion:** ✅ **NO CODE SETS `modulate` WITH ALPHA = 0**

---

## 4. `queue_free()` CALLS ON RACE NODES

### Search Pattern: `queue_free\(\)`

**Found 13 occurrences total, but only 3 are race-related:**

### ✅ SAFE `queue_free()` CALLS (Clearing Children Before Re-population)

#### 4.1 RaceTab.gd - Lines 54, 56, 58

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Context:** Clearing existing entries before re-populating columns

```52:58:scripts/character_creation/tabs/RaceTab.gd
	# Clear existing entries
	for child in column_1.get_children():
		child.queue_free()
	for child in column_2.get_children():
		child.queue_free()
	for child in column_3.get_children():
		child.queue_free()
```

**Analysis:**
- ✅ **SAFE:** This clears OLD entries before adding new ones
- These are children of the column VBoxContainers
- This is normal cleanup behavior - removes previous race entries before re-populating
- **NOT hiding race nodes** - just cleaning up before adding fresh entries

#### 4.2 RaceTab.gd - Line 140

**File:** `scripts/character_creation/tabs/RaceTab.gd`  
**Context:** Removing existing VSpacer before adding a new one

```137:140:scripts/character_creation/tabs/RaceTab.gd
		# Remove any existing spacer
		var existing_spacer: Node = content.get_node_or_null("VSpacer")
		if existing_spacer:
			existing_spacer.queue_free()
```

**Analysis:**
- ✅ **SAFE:** Only removes spacer nodes, NOT race entries
- This is cleanup code to prevent duplicate spacers

#### 4.3 RaceEntry.gd - Line 105

**File:** `scripts/character_creation/tabs/components/RaceEntry.gd`  
**Context:** Removing old icon placeholder before adding a new one

```103:105:scripts/character_creation/tabs/components/RaceEntry.gd
	for child in icon.get_children():
		if child.name == "Placeholder":
			child.queue_free()
```

**Analysis:**
- ✅ **SAFE:** Only removes placeholder ColorRect inside the icon TextureRect
- This is cleanup for icon placeholders, NOT race entry nodes
- Does NOT affect race entry visibility

---

### ⚠️ CharacterCreationRoot.gd - Line 116

**File:** `scripts/character_creation/CharacterCreationRoot.gd`  
**Context:** Freeing previous tab instance when switching tabs

```114:116:scripts/character_creation/CharacterCreationRoot.gd
func _load_tab(tab_name: String) -> void:
	if current_tab_instance:
		current_tab_instance.queue_free()
```

**Analysis:**
- ⚠️ **POTENTIAL ISSUE:** This frees the ENTIRE RaceTab instance when switching away from it
- However, this is expected behavior when switching tabs
- The RaceTab will be re-instantiated when switching back
- This is NOT hiding race nodes - it's switching tabs

**Impact:** When you switch FROM Race tab TO another tab, the entire RaceTab (including all race entries) is freed. When you switch BACK to Race tab, it's re-created.

---

## 5. RACE CONTAINER NODE SEARCH

### Search Pattern: `RaceContainer|race_container|Race.*Container`

**Result:** ✅ **NO MATCHES FOUND**

**Conclusion:** No nodes named "RaceContainer" exist in the codebase. Race entries are added directly to:
- `Column1Content` (VBoxContainer)
- `Column2Content` (VBoxContainer)
- `Column3Content` (VBoxContainer)

---

## 6. SUMMARY OF FINDINGS

### ✅ NO PROBLEMATIC CODE FOUND:

1. **No `.hide()` calls** - None found anywhere
2. **No `visible = false` assignments** - None found anywhere
3. **No `modulate` with alpha = 0** - None found in code
4. **No `queue_free()` on race entries** - Only cleanup code that's expected:
   - Clearing old entries before re-population (lines 54, 56, 58 in RaceTab.gd)
   - Removing spacer nodes (line 140 in RaceTab.gd)
   - Removing icon placeholders (line 105 in RaceEntry.gd)

### ⚠️ ONE POTENTIAL CONCERN:

- **CharacterCreationRoot.gd line 116:** Frees entire RaceTab when switching tabs
  - This is expected behavior for tab switching
  - RaceTab is re-created when switching back
  - **NOT causing permanent hiding of race nodes**

---

## 7. COMPLETE FILE + LINE NUMBER LIST

### RaceTab.gd
- **Line 54:** `child.queue_free()` - Clears column_1 children (SAFE)
- **Line 56:** `child.queue_free()` - Clears column_2 children (SAFE)
- **Line 58:** `child.queue_free()` - Clears column_3 children (SAFE)
- **Line 140:** `existing_spacer.queue_free()` - Removes spacer (SAFE)

### RaceEntry.gd
- **Line 105:** `child.queue_free()` - Removes icon placeholder (SAFE)

### CharacterCreationRoot.gd
- **Line 116:** `current_tab_instance.queue_free()` - Frees tab when switching (EXPECTED)

---

## 8. CONCLUSION

**✅ NO CODE IS HIDING RACE NODES:**

- No `.hide()` calls found
- No `visible = false` assignments found
- No `modulate` transparency found
- `queue_free()` calls are only for:
  - Normal cleanup before re-population
  - Removing temporary spacers/placeholders
  - Tab switching behavior (expected)

**If race columns are not displaying, the issue is NOT caused by code hiding/freeing race nodes.**

The problem must be in:
- Layout/sizing issues
- Container configuration
- Rendering/layer issues
- Scene structure problems

---

**Report Generated:** Complete search for race node visibility/hiding code

