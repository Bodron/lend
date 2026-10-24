export async function getServerSideProps() {
  return {
    redirect: {
      destination: "/",
      permanent: true,
    },
  };
}

export default function ArchiveRedirect() {
  return null;
}
