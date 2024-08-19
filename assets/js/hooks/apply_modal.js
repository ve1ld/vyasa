const ApplyModal = () => {
  const modal = document.querySelector('[data-selector="vyasa_modal_message"]')

  if (!modal) return

  const encodedReturnTo = encodeURIComponent(document.location.pathname)

  modal.querySelectorAll('a[data-phx-link="redirect"]').forEach(val => {
    const url = new URL(val.href, document.location.origin)
    url.searchParams.set('return_to', encodedReturnTo)
    val.href = `${url.href}`
  })
}

export default ApplyModal
