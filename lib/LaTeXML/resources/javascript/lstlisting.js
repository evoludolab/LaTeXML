// replace download links in lstlisting environments by copy to clipboard button
// requires images/copy.svg and images/ok.svg
// (c) Christoph Hauert 2025

window.addEventListener("load", () => {
	const elements = document.getElementsByClassName("ltx_listing_data");
	const copyButton = '<div class="ltx_listing_copy2clip"><button class="ltx_listing_button" onclick="copy2clip(this)" title="Copy to clipboard"><img class="ltx_listing_copy" src="images/copy.svg"></button></div>';
	Array.from(elements).forEach(el => {
		if (el.firstChild) {
			el.removeChild(el.firstChild);
		}
		el.insertAdjacentHTML('afterbegin', copyButton);
	});
});

function copy2clip(button) {
	try {
		// temporarily hide line numbers in code listing
	    const style = document.createElement('style');
	    document.head.appendChild(style);
	    const styleSheet = style.sheet;
		var hideLine = styleSheet.insertRule(".ltx_tag_listingline { display: none; }");
		var hideCopy = styleSheet.insertRule(".ltx_listing_data { display: none; }");
	    const textToCopy = button.parentNode.parentNode.parentNode.innerText;
		navigator.clipboard.writeText(textToCopy);
		styleSheet.deleteRule(hideCopy);
		styleSheet.deleteRule(hideLine);
  		const container = button.parentElement;
		const img = document.createElement('img');
		img.src = 'images/ok.svg';
		img.className = 'ltx_listing_copy_ok';
		container.appendChild(img);
		button.getElementsByClassName('ltx_listing_copy')[0].classList.add('hide');
		setTimeout(() => {
			button.getElementsByClassName('ltx_listing_copy')[0].classList.remove('hide');
			container.removeChild(img);
		}, 1000);
	} catch (err) {
		alert('Failed to copy text: ' + err);
	}
}
