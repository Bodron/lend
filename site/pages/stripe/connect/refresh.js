export async function getServerSideProps() {
  return { redirect: { destination: "/account?stripe=refresh", permanent: false } };
}

export default function StripeConnectRefresh() {
  return null;
}
