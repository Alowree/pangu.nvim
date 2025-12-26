`Cleanup` Logic

Let's tweak further for better visual effect after the ignore tags are removed. When run the `PanguIgnoreCleanup` command to:

## Look for the ignore tags

It should firstly look upward for the ignore start tag and downward for the ignore end tag.

### when both tags are found

#### check the line status of both above and below the ignore tag lines

<!-- prettier-ignore-start -->

case 1: if one blank line both above and below the ignore tag lines, first convert such tag line into a blank line, then (we will have total 3 blank lines above/below the CONTENT) delete 2 blank lines and keep 1 blank line above/below the CONTENT.

Input:

```md
<!-- blank line above the tag -->
<!-- pangu-ignore-start -->
<!-- blank line below the tag -->

CONTENT = current line or a block of multiple lines

<!-- blank line above the tag -->
<!-- pangu-ignore-end -->
<!-- blank line below the tag -->
```

Output:

```md
<!-- blank line above the tag --> Eventually deleted
<!-- pangu-ignore-start --> Eventually deleted
<!-- blank line below the tag -->

CONTENT = current line or a block of multiple lines

<!-- blank line above the tag -->
<!-- pangu-ignore-end --> Eventually deleted
<!-- blank line below the tag --> Eventually deleted
```

case 2: if only one blank line either above or below the ignore tag line, first convert such tag line into a blank line, then (will have total 2 blank lines above/below the CONTENT) delete 1 blank line and keep 1 blank line above/below the CONTENT.

Input:

```md
<!-- not a blank line -->
<!-- pangu-ignore-start -->
<!-- blank line below the tag -->

CONTENT = current line or a block of multiple lines

<!-- not a blank line -->
<!-- pangu-ignore-end -->
<!-- blank line below the tag -->
```

Output:

```md
<!-- not a blank line -->
<!-- pangu-ignore-start --> Eventually deleted
<!-- blank line below the tag -->

CONTENT = current line or a block of multiple lines

<!-- not a blank line -->
<!-- pangu-ignore-end --> Eventually deleted
<!-- blank line below the tag -->
```

case 3: if no blank lines both above and below the ignore tag lines, then merely convert such tag line into a blank line

Input:

```md
<!-- not a blank line -->
<!-- pangu-ignore-start -->
<!-- not a blank line -->

CONTENT = current line or a block of multiple lines

<!-- not a blank line -->
<!-- pangu-ignore-end -->
<!-- not a blank line -->
```

Output:

```md
<!-- not a blank line -->
<!-- pangu-ignore-start --> Convert this to a blank line
<!-- not a blank line -->

CONTENT = current line or a block of multiple lines

<!-- not a blank line -->
<!-- pangu-ignore-end --> Convert this to a blank line
<!-- not a blank line -->
```

### when looking upward and the ignore end tag found

Abort with proper hinting message

### when looking downward and the ignore start tag found

Abort with proper hinting message
